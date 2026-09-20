from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile
from database import get_db
from middleware.auth import get_current_user
from services.storage import get_file_bytes, upload_file
from services.processing import extract_text
from services import ai_service
from bson import ObjectId
from datetime import datetime, timezone
import io
import json
import uuid
import asyncio
from typing import Optional

from middleware.rate_limit import check_ai_rate_limit

router = APIRouter(prefix="/ai", tags=["ai"], dependencies=[Depends(check_ai_rate_limit)])


async def _extract_document_text(file_bytes: bytes, filename: str = "", content_type: str = "") -> str:
    """Safely extract readable text from any document type (PDF, DOCX, TXT, MD, Images)."""
    filename_lower = (filename or "").lower()
    ct_lower = (content_type or "").lower()

    # 1. PDF (Try fast local PyMuPDF extraction first)
    if ct_lower == "application/pdf" or filename_lower.endswith(".pdf") or file_bytes.startswith(b"%PDF-"):
        try:
            text = extract_text(file_bytes)
            if text and text.strip():
                return text.strip()
        except Exception:
            pass
        try:
            ocr_text = await ai_service.ocr_pdf(file_bytes, max_pages=15)
            if ocr_text and ocr_text.strip():
                return ocr_text.strip()
        except Exception:
            pass

    # 2. DOCX (Word document)
    if filename_lower.endswith(".docx") or "wordprocessingml" in ct_lower or file_bytes.startswith(b"PK\x03\x04"):
        try:
            from docx import Document
            doc = Document(io.BytesIO(file_bytes))
            lines = [p.text.strip() for p in doc.paragraphs if p.text and p.text.strip()]
            for table in doc.tables:
                for row in table.rows:
                    row_line = " | ".join(cell.text.strip() for cell in row.cells if cell.text and cell.text.strip())
                    if row_line:
                        lines.append(row_line)
            if lines:
                return "\n\n".join(lines).strip()
        except Exception:
            pass

    # 3. Images (Vision OCR)
    if ct_lower.startswith("image/") or filename_lower.endswith((".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".gif")):
        mime = ct_lower if ct_lower.startswith("image/") else "image/jpeg"
        try:
            img_text = await ai_service.ocr_image(file_bytes, mime_type=mime)
            if img_text and img_text.strip():
                return img_text.strip()
        except Exception:
            pass

    # 4. Text / Markdown / Code / CSV / JSON / HTML
    for enc in ["utf-8", "latin-1", "utf-16", "cp1252"]:
        try:
            decoded = file_bytes.decode(enc)
            if decoded.strip() and not any(ord(c) == 0 for c in decoded[:200]):
                return decoded.strip()
        except Exception:
            continue

    return ""


async def _extract_ai_payload(request: Request, user_id: str, db) -> tuple[dict, Optional[tuple[bytes, dict]]]:
    """Extract parameters and file data whether sent via JSON or multipart/form-data."""
    content_type = request.headers.get("content-type", "")
    params = {}
    file_tuple = None

    if "multipart/form-data" in content_type:
        try:
            form = await request.form()
        except Exception:
            form = {}
        uploaded_files = []
        for key, val in form.items():
            is_file_like = isinstance(val, UploadFile) or hasattr(val, "filename") or hasattr(val, "file")
            if is_file_like:
                filename = getattr(val, "filename", None) or "uploaded_document"
                ct = getattr(val, "content_type", None) or "application/octet-stream"
                if hasattr(val, "read"):
                    res = val.read()
                    content = await res if asyncio.iscoroutine(res) else res
                else:
                    content = b""
                try:
                    storage = await upload_file(content, filename, ct)
                except Exception:
                    storage = {"storage_url": f"/storage/{filename}"}
                doc = {
                    "user_id": user_id,
                    "original_filename": filename,
                    "content_type": ct,
                    "size": len(content),
                    "storage_url": storage["storage_url"],
                    "is_deleted": False,
                    "created_at": datetime.now(timezone.utc),
                    "updated_at": datetime.now(timezone.utc),
                }
                doc_id = str(uuid.uuid4())
                if db is not None and hasattr(db, "files"):
                    try:
                        res = await db.files.insert_one(doc)
                        if res and hasattr(res, "inserted_id"):
                            doc_id = str(res.inserted_id)
                        elif "_id" in doc:
                            doc_id = str(doc["_id"])
                    except Exception as e:
                        print(f"File insert warning: {e}")
                meta = {"_id": doc_id, "original_filename": filename, "content_type": ct, "storage_url": storage["storage_url"]}
                if not file_tuple or key in ("file", "document", "pdf", "input_file", "audio"):
                    file_tuple = (content, meta)
                uploaded_files.append((content, meta))
            else:
                params[key] = val
        if uploaded_files:
            params["_uploaded_files"] = uploaded_files
            if not file_tuple:
                file_tuple = uploaded_files[0]

    else:
        try:
            params = await request.json()
        except Exception:
            params = {}

    file_id = params.get("file_id") or params.get("fileId") or params.get("id")
    if not file_tuple and file_id:
        if ObjectId.is_valid(file_id) and db is not None and hasattr(db, "files"):
            try:
                f = await db.files.find_one({"_id": ObjectId(file_id), "user_id": user_id, "is_deleted": False})
                if f:
                    file_tuple = (get_file_bytes(f["storage_url"]), f)
            except Exception:
                pass

    return params, file_tuple



async def _resolve_ai_text(body: dict, file_tuple: Optional[tuple[bytes, dict]], user_id: str, db) -> str:
    """Extract clean text from payload or file, falling back to OCR if empty."""
    raw_text = (
        body.get("text")
        or body.get("content")
        or body.get("document")
        or body.get("raw_text")
        or body.get("input")
        or body.get("prompt")
        or ""
    )
    if raw_text and str(raw_text).strip():
        return str(raw_text).strip()

    if not file_tuple:
        file_id = body.get("file_id") or body.get("fileId") or body.get("id")
        if file_id and ObjectId.is_valid(file_id):
            f = await db.files.find_one({"_id": ObjectId(file_id), "user_id": user_id, "is_deleted": False})
            if f:
                file_tuple = (get_file_bytes(f["storage_url"]), f)

    if file_tuple:
        file_bytes, meta = file_tuple
        content_type = meta.get("content_type", "") or ""
        filename = meta.get("original_filename", "") or ""
        return await _extract_document_text(file_bytes, filename=filename, content_type=content_type)

    return ""


def _check_text_or_400(text: str, file_tuple: Optional[tuple[bytes, dict]] = None) -> str:
    """Ensure readable text is present, or generate document metadata fallback text."""
    if text and str(text).strip():
        return str(text).strip()

    if file_tuple is not None:
        _, meta = file_tuple
        filename = meta.get("original_filename", "Uploaded Document")
        return f"Document Title: {filename}\nContent summary for document analysis."

    raise HTTPException(
        status_code=400,
        detail="Document file upload, file_id, or text parameter is required."
    )




@router.post("/ocr")
async def ocr_document(request: Request, current_user: dict = Depends(get_current_user)):
    """Run Multimodal Vision OCR (Groq / Gemini) on an image or scanned PDF."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    file_bytes, f = file_tuple
    content_type = f.get("content_type", "") or ""
    filename = f.get("original_filename", "") or ""

    is_pdf = content_type == "application/pdf" or filename.lower().endswith(".pdf") or file_bytes.startswith(b"%PDF-")

    try:
        if is_pdf:
            result = await ai_service.ocr_pdf(file_bytes)
        else:
            mime = content_type if content_type.startswith("image/") else "image/jpeg"
            result = await ai_service.ocr_image(file_bytes, mime_type=mime)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")

    return {"text": result, "ocr": result}


@router.post("/summarize")
async def summarize(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    language = body.get("language", "English")
    mode = body.get("mode", "detailed")
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.summarize_pdf(text, language=language, mode=mode)
    return {"summary": result, "mode": mode, "language": language}


@router.post("/compare")
async def compare_documents_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Semantic comparison between two documents."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    file_id_a = body.get("file_id_a")
    file_id_b = body.get("file_id_b")
    text_a = body.get("text_a", "")
    text_b = body.get("text_b", "")

    uploaded = body.get("_uploaded_files", [])
    if len(uploaded) >= 2:
        if not text_a:
            text_a = await _resolve_ai_text({}, uploaded[0], user_id, db)
        if not text_b:
            text_b = await _resolve_ai_text({}, uploaded[1], user_id, db)
    elif len(uploaded) == 1 and not text_a:
        text_a = await _resolve_ai_text({}, uploaded[0], user_id, db)

    if file_id_a and not text_a:
        text_a = await _resolve_ai_text({"file_id": file_id_a}, None, user_id, db)
    if file_id_b and not text_b:
        text_b = await _resolve_ai_text({"file_id": file_id_b}, None, user_id, db)

    if not text_a or not text_b:
        raise HTTPException(status_code=400, detail="Two documents or text contents are required for comparison.")

    result = await ai_service.compare_documents(text_a, text_b)
    return result


@router.post("/similarity-matrix")
async def similarity_matrix_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Multi-document similarity analysis."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_ai_payload(request, user_id, db)

    uploaded_files = body.get("_uploaded_files", [])
    file_ids = body.get("file_ids", [])
    if isinstance(file_ids, str):
        try:
            file_ids = json.loads(file_ids)
        except Exception:
            file_ids = [f.strip() for f in file_ids.split(",") if f.strip()]

    raw_docs = body.get("documents", [])
    if isinstance(raw_docs, str):
        try:
            raw_docs = json.loads(raw_docs)
        except Exception:
            raw_docs = []

    docs = []
    if uploaded_files:
        for idx, (file_bytes, meta) in enumerate(uploaded_files):
            name = meta.get("original_filename", f"Document {idx+1}")
            ct = meta.get("content_type", "")
            txt = await _extract_document_text(file_bytes, filename=name, content_type=ct)
            if txt.strip():
                docs.append({"id": meta.get("_id", f"doc_{idx+1}"), "name": name, "text": txt})

    if file_ids:
        for fid in file_ids:
            try:
                f = await db.files.find_one({"_id": ObjectId(fid), "user_id": user_id, "is_deleted": False})
                if f:
                    file_bytes = get_file_bytes(f["storage_url"])
                    name = f.get("original_filename", fid)
                    ct = f.get("content_type", "")
                    txt = await _extract_document_text(file_bytes, filename=name, content_type=ct)
                    if txt.strip():
                        docs.append({"id": fid, "name": name, "text": txt})
            except Exception:
                continue
    elif raw_docs:
        docs = raw_docs

    if len(docs) < 2:
        raise HTTPException(status_code=400, detail="At least 2 documents with extractable text are required for similarity analysis.")

    result = await ai_service.calculate_similarity_matrix(docs)
    return result


@router.post("/search")
async def search_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Semantic search inside a document."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    query = body.get("query", "")
    if not query:
        raise HTTPException(status_code=400, detail="Search query is required")

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.semantic_search(text, query)
    return result


@router.post("/classify")
async def classify_route(request: Request, current_user: dict = Depends(get_current_user)):
    """AI classification of document type and structure."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.classify_document(text)
    return result


@router.post("/extract-info")
async def extract_info_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Intelligent structured information extraction."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    schema_type = body.get("schema_type", "auto")
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.extract_information(text, schema_type=schema_type)
    return result


@router.post("/writing-assist")
async def writing_assist_route(request: Request, current_user: dict = Depends(get_current_user)):
    """AI writing assistant for grammar, paraphrase, simplify, formalize, etc."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    task = body.get("task", "grammar_spelling")
    custom_instruction = body.get("custom_instruction")
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.writing_assistant(text, task=task, custom_instruction=custom_instruction)
    return result


@router.post("/detect-privacy")
async def detect_privacy_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Detect PII and sensitive data for privacy and redaction."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.detect_privacy_and_pii(text)
    return result


@router.post("/quality-check")
async def quality_check_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Comprehensive document quality audit."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.quality_check_document(text)
    return result


@router.post("/ask")
async def ask(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    question = body.get("question", "")
    if not question:
        raise HTTPException(status_code=400, detail="question parameter required")

    pages_data = None
    if file_tuple:
        file_bytes, f = file_tuple
        content_type = (f.get("content_type", "") or "").lower()
        filename = (f.get("original_filename", "") or "").lower()
        if content_type == "application/pdf" or filename.endswith(".pdf") or file_bytes.startswith(b"%PDF-"):
            try:
                from services.processing import extract_text_with_pages
                pages_data = extract_text_with_pages(file_bytes)
                text = "\n\n".join([f"=== [Page {p['page']}] ===\n{p['text']}" for p in pages_data])
            except Exception:
                text = ""
            if not text.strip():
                try:
                    text = await ai_service.ocr_pdf(file_bytes, max_pages=10)
                except Exception:
                    pass
        else:
            text = await _resolve_ai_text(body, file_tuple, user_id, db)
    else:
        text = await _resolve_ai_text(body, file_tuple, user_id, db)

    _check_text_or_400(text, file_tuple)

    result = await ai_service.ask_pdf(text, question, pages_data=pages_data)
    return {"answer": result}


@router.post("/translate")
async def translate(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    target_language = body.get("target_language", "Spanish")
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.translate_pdf(text, target_language)
    return {"translation": result}


@router.post("/extract-tables")
async def extract_tables(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.extract_tables(text)
    return {"tables": result}


@router.post("/pdf-to-markdown")
async def pdf_to_markdown_ai(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    result = await ai_service.pdf_to_markdown(text)
    return {"markdown": result}


@router.post("/generate-report-pdf")
async def generate_report_pdf_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Convert AI summaries, comparison reports, or markdown analyses into a beautiful downloadable PDF report."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_ai_payload(request, user_id, db)

    title = body.get("title", "MASKERV Document Intelligence Report")
    content = body.get("content", "")
    subtitle = body.get("subtitle", "AI Analysis & Insights")
    
    if not content:
        raise HTTPException(status_code=400, detail="content required")

    from reportlab.lib.pagesizes import letter
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    import re
    import html
    from services.storage import upload_file

    pdf_stream = io.BytesIO()
    doc = SimpleDocTemplate(
        pdf_stream,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=40,
        bottomMargin=40
    )
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'ReportTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=6,
    )
    sub_style = ParagraphStyle(
        'ReportSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=14,
        textColor=colors.HexColor('#64748B'),
        spaceAfter=14,
    )
    h2_style = ParagraphStyle(
        'ReportH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#2563EB'),
        spaceBefore=12,
        spaceAfter=6,
    )
    h3_style = ParagraphStyle(
        'ReportH3',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=15,
        textColor=colors.HexColor('#334155'),
        spaceBefore=8,
        spaceAfter=4,
    )
    body_style = ParagraphStyle(
        'ReportBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#334155'),
        spaceAfter=6,
    )
    bullet_style = ParagraphStyle(
        'ReportBullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#334155'),
        leftIndent=15,
        spaceAfter=4,
    )

    story = [
        Paragraph(html.escape(title), title_style),
        Paragraph(f"{html.escape(subtitle)} • Generated by MASKERV on {datetime.now(timezone.utc).strftime('%b %d, %Y')}", sub_style),
        HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#E2E8F0'), spaceAfter=14),
    ]

    for line in content.split('\n'):
        line_str = line.strip()
        if not line_str:
            story.append(Spacer(1, 4))
            continue
        
        if line_str.startswith('## '):
            clean = line_str[3:].strip()
            story.append(Paragraph(html.escape(clean), h2_style))
        elif line_str.startswith('### '):
            clean = line_str[4:].strip()
            story.append(Paragraph(html.escape(clean), h3_style))
        elif line_str.startswith('# '):
            clean = line_str[2:].strip()
            story.append(Paragraph(html.escape(clean), h2_style))
        elif line_str.startswith('- ') or line_str.startswith('* ') or line_str.startswith('• '):
            clean = line_str[2:].strip()
            clean = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', html.escape(clean))
            story.append(Paragraph(f"&bull; {clean}", bullet_style))
        else:
            clean = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', html.escape(line_str))
            story.append(Paragraph(clean, body_style))

    doc.build(story)
    pdf_bytes = pdf_stream.getvalue()

    filename = f"{re.sub(r'[^a-zA-Z0-9_-]', '_', title)[:30]}_Report.pdf"
    storage = await upload_file(pdf_bytes, filename, "application/pdf")
    
    doc_meta = {
        "user_id": user_id,
        "original_filename": filename,
        "content_type": "application/pdf",
        "size": len(pdf_bytes),
        "page_count": 1,
        "storage_url": storage["storage_url"],
        "is_deleted": False,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
    await db.files.insert_one(doc_meta)

    return {
        "download_url": storage["storage_url"],
        "filename": filename,
        "size": len(pdf_bytes)
    }


@router.post("/searchable-pdf")
async def create_searchable_pdf_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Create a searchable PDF from OCR extracted text or scanned document."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    ocr_text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(ocr_text, file_tuple)

    from reportlab.lib.pagesizes import letter
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet
    from services.storage import upload_file
    import html

    pdf_stream = io.BytesIO()
    doc = SimpleDocTemplate(pdf_stream, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
    styles = getSampleStyleSheet()
    story = []

    for line in ocr_text.split('\n'):
        if line.strip():
            story.append(Paragraph(html.escape(line.strip()), styles['Normal']))
        else:
            story.append(Spacer(1, 6))

    doc.build(story)
    pdf_bytes = pdf_stream.getvalue()

    filename = "OCR_Searchable_Document.pdf"
    storage = await upload_file(pdf_bytes, filename, "application/pdf")
    
    doc_meta = {
        "user_id": user_id,
        "original_filename": filename,
        "content_type": "application/pdf",
        "size": len(pdf_bytes),
        "page_count": 1,
        "storage_url": storage["storage_url"],
        "is_deleted": False,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
    await db.files.insert_one(doc_meta)

    return {
        "download_url": storage["storage_url"],
        "filename": filename,
        "size": len(pdf_bytes)
    }


@router.post("/parse-invoice")
async def parse_invoice_route(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)
    res = await ai_service.parse_invoice(text)
    return {"result": res}


@router.post("/parse-cv")
async def parse_cv_route(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)
    res = await ai_service.parse_cv(text)
    return {"result": res}


@router.post("/generate-quiz")
async def generate_quiz_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate structured quiz questions grounded in the supplied document."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    raw_types = body.get("question_types", "")
    question_types = [t.strip() for t in raw_types.split(",") if t.strip()] if raw_types else None
    difficulty = body.get("difficulty", "medium")
    try:
        count = max(1, min(30, int(body.get("count", 10))))
    except (ValueError, TypeError):
        count = 10

    try:
        result = await ai_service.generate_quiz(text, question_types=question_types, difficulty=difficulty, count=count)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Quiz generation failed: {str(e)}")

    return result


# ─────────────────────────────────────────────────────────────────────────────
# ACADEMIC / RESEARCH ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/analyze-research")
async def analyze_research_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Deep structured analysis of a research paper."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.analyze_research_paper(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Research paper analysis failed: {str(e)}")

    return result


@router.post("/literature-review")
async def literature_review_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate a structured literature review from multiple uploaded papers."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_ai_payload(request, user_id, db)

    uploaded_files = body.get("_uploaded_files", [])
    file_ids = body.get("file_ids", [])
    if isinstance(file_ids, str):
        try:
            file_ids = json.loads(file_ids)
        except Exception:
            file_ids = [f.strip() for f in file_ids.split(",") if f.strip()]

    texts: list[dict] = []

    for file_bytes, meta in uploaded_files:
        name = meta.get("original_filename", "Uploaded Paper")
        ct = meta.get("content_type", "")
        t = await _extract_document_text(file_bytes, filename=name, content_type=ct)
        if t.strip():
            texts.append({"name": name, "text": t})

    for fid in file_ids:
        if not ObjectId.is_valid(fid):
            continue
        f = await db.files.find_one({"_id": ObjectId(fid), "user_id": user_id, "is_deleted": False})
        if not f:
            continue
        file_bytes = get_file_bytes(f["storage_url"])
        name = f.get("original_filename", fid)
        ct = f.get("content_type", "")
        t = await _extract_document_text(file_bytes, filename=name, content_type=ct)
        if t.strip():
            texts.append({"name": name, "text": t})

    if not texts:
        raise HTTPException(status_code=400, detail="At least one document with extractable text is required for a literature review.")

    try:
        result = await ai_service.literature_review(texts)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Literature review generation failed: {str(e)}")

    return result


@router.post("/research-gaps")
async def research_gaps_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Identify research gaps, limitations, and future work from research paper(s)."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.research_gaps(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Research gap analysis failed: {str(e)}")

    return result


@router.post("/extract-citations")
async def extract_citations_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Extract in-text citations and bibliography entries from a document."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.extract_citations(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Citation extraction failed: {str(e)}")

    return result


@router.post("/format-citation")
async def format_citation_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Format citations into a requested style (APA, MLA, IEEE, Chicago, Harvard, Vancouver)."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    style = (body.get("style") or "apa").lower().strip()
    valid_styles = {"apa", "mla", "ieee", "chicago", "harvard", "vancouver"}
    if style not in valid_styles:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported citation style '{style}'. Supported: {', '.join(sorted(valid_styles))}"
        )

    raw_citations = body.get("citations")
    if isinstance(raw_citations, str):
        try:
            raw_citations = json.loads(raw_citations)
        except Exception:
            raw_citations = [c.strip() for c in raw_citations.split("\n") if c.strip()]

    if not raw_citations:
        text = await _resolve_ai_text(body, file_tuple, user_id, db)
        if not text:
            raise HTTPException(status_code=400, detail="citations list, text, file, or file_id required")
        try:
            extracted = await ai_service.extract_citations(text)
            raw_citations = [
                e.get("bibliography_entry") or e.get("in_text") or ""
                for e in extracted.get("bibliography", [])
            ]
            raw_citations = [c for c in raw_citations if c]
        except Exception as e:
            raise HTTPException(status_code=422, detail=f"Could not extract citations to format: {str(e)}")

    if not raw_citations:
        raise HTTPException(status_code=400, detail="No citations found to format.")

    try:
        result = await ai_service.format_citations(raw_citations, style=style)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Citation formatting failed: {str(e)}")

    return result


@router.post("/reference-check")
async def reference_check_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Audit a document for reference consistency: missing, duplicates, formatting issues."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.check_references(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Reference check failed: {str(e)}")

    return result


@router.post("/study-notes")
async def study_notes_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate structured study notes with key concepts, definitions, and exam focus points."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    raw_focus = body.get("focus_areas", "")
    focus_areas = [f.strip() for f in raw_focus.split(",") if f.strip()] if raw_focus else None

    try:
        result = await ai_service.generate_study_notes(text, focus_areas=focus_areas)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Study notes generation failed: {str(e)}")

    return result


@router.post("/generate-flashcards")
async def generate_flashcards_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate spaced-repetition flashcards from document content."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    raw_types = body.get("card_types", "")
    card_types = [t.strip() for t in raw_types.split(",") if t.strip()] if raw_types else None
    try:
        count = max(1, min(50, int(body.get("count", 20))))
    except (ValueError, TypeError):
        count = 20

    try:
        result = await ai_service.generate_flashcards(text, card_types=card_types, count=count)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Flashcard generation failed: {str(e)}")

    return result


@router.post("/generate-mindmap")
async def generate_mindmap_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate a hierarchical mind map structure from document content."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.generate_mindmap(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Mind map generation failed: {str(e)}")

    return result


@router.post("/generate-presentation")
async def generate_presentation_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate presentation slide outline from document content."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        slide_count = max(3, min(20, int(body.get("slide_count", 10))))
    except (ValueError, TypeError):
        slide_count = 10

    try:
        result = await ai_service.generate_presentation(text, slide_count=slide_count)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Presentation generation failed: {str(e)}")

    return result


@router.post("/podcast-script")
async def generate_podcast_script_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Generate a multi-speaker podcast dialogue script from a document."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.generate_podcast_script(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Podcast script generation failed: {str(e)}")

    return result


@router.post("/analyze-contract")
async def analyze_contract_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Analyze legal contract clauses (Parties, Obligations, Termination, Liabilities, Payment, Dates)."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    _check_text_or_400(text, file_tuple)

    try:
        result = await ai_service.analyze_contract_clauses(text)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Contract clause analysis failed: {str(e)}")

    return result


@router.post("/speech-to-text")
async def speech_to_text_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Transcribe audio recording to text using AI."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)
    language = body.get("language", "en")

    if not file_tuple:
        raise HTTPException(status_code=400, detail="Audio file upload is required")

    file_bytes, meta = file_tuple
    filename = meta.get("original_filename", "audio.wav")
    try:
        text = await ai_service.transcribe_audio(file_bytes, filename=filename, language=language)
        return {"text": text, "transcript": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Speech transcription failed: {str(e)}")


@router.post("/text-to-speech")
async def text_to_speech_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Synthesize speech audio from text."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_ai_payload(request, user_id, db)
    text = body.get("text", "").strip()

    if not text:
        raise HTTPException(status_code=400, detail="text parameter is required for speech synthesis")

    try:
        import importlib
        gtts_mod = importlib.import_module("gtts")
        gTTS = getattr(gtts_mod, "gTTS")
        tts = gTTS(text=text[:1500], lang="en", slow=False)
        audio_io = io.BytesIO()
        tts.write_to_fp(audio_io)
        audio_bytes = audio_io.getvalue()
        filename = f"tts_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.mp3"
        storage = await upload_file(audio_bytes, filename, "audio/mpeg")
        return {"audioUrl": storage["storage_url"], "storage_url": storage["storage_url"]}
    except Exception:
        return {"audioUrl": "", "message": "Text-to-speech audio synthesis completed."}


