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
from typing import Optional

from middleware.rate_limit import check_ai_rate_limit

router = APIRouter(prefix="/ai", tags=["ai"], dependencies=[Depends(check_ai_rate_limit)])


async def _extract_ai_payload(request: Request, user_id: str, db) -> tuple[dict, Optional[tuple[bytes, dict]]]:
    """Extract parameters and file data whether sent via JSON or multipart/form-data."""
    content_type = request.headers.get("content-type", "")
    params = {}
    file_tuple = None

    if "multipart/form-data" in content_type:
        form = await request.form()
        uploaded_files = []
        for key, val in form.items():
            if isinstance(val, UploadFile):
                content = await val.read()
                filename = val.filename or "uploaded_document"
                ct = val.content_type or "application/octet-stream"
                storage = await upload_file(content, filename, ct)
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
                await db.files.insert_one(doc)
                meta = {"_id": str(doc["_id"]), "original_filename": filename, "content_type": ct, "storage_url": storage["storage_url"]}
                if key == "file" or not file_tuple:
                    file_tuple = (content, meta)
                uploaded_files.append((content, meta))
            else:
                params[key] = val
        if uploaded_files:
            params["_uploaded_files"] = uploaded_files
    else:
        try:
            params = await request.json()
        except Exception:
            params = {}

    file_id = params.get("file_id")
    if not file_tuple and file_id:
        if ObjectId.is_valid(file_id):
            f = await db.files.find_one({"_id": ObjectId(file_id), "user_id": user_id, "is_deleted": False})
            if f:
                file_tuple = (get_file_bytes(f["storage_url"]), f)

    return params, file_tuple


async def _resolve_ai_text(body: dict, file_tuple: Optional[tuple[bytes, dict]], user_id: str, db) -> str:
    """Extract clean text from payload or file, falling back to OCR if empty."""
    raw_text = body.get("text", "")
    if raw_text and str(raw_text).strip():
        return str(raw_text).strip()

    if not file_tuple:
        file_id = body.get("file_id")
        if file_id and ObjectId.is_valid(file_id):
            f = await db.files.find_one({"_id": ObjectId(file_id), "user_id": user_id, "is_deleted": False})
            if f:
                file_tuple = (get_file_bytes(f["storage_url"]), f)

    if file_tuple:
        file_bytes, meta = file_tuple
        content_type = meta.get("content_type", "") or ""
        filename = meta.get("original_filename", "") or ""

        if content_type == "application/pdf" or filename.lower().endswith(".pdf") or file_bytes.startswith(b"%PDF-"):
            text = extract_text(file_bytes)
            if not text.strip():
                try:
                    text = await ai_service.ocr_pdf(file_bytes, max_pages=10)
                except Exception as e:
                    raise HTTPException(status_code=422, detail=f"PDF contains no digital text and OCR failed: {str(e)}")
            return text
        elif content_type.startswith("image/") or filename.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
            mime = content_type if content_type.startswith("image/") else "image/jpeg"
            return await ai_service.ocr_image(file_bytes, mime_type=mime)
        else:
            try:
                return file_bytes.decode("utf-8", errors="ignore")
            except Exception:
                pass
    return ""


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

    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

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

    if file_id_a and not text_a:
        text_a = await _resolve_ai_text({"file_id": file_id_a}, None, user_id, db)
    if file_id_b and not text_b:
        text_b = await _resolve_ai_text({"file_id": file_id_b}, None, user_id, db)

    if not text_a or not text_b:
        raise HTTPException(status_code=400, detail="Two documents or texts are required for comparison")

    result = await ai_service.compare_documents(text_a, text_b)
    return result


@router.post("/similarity-matrix")
async def similarity_matrix_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Multi-document similarity analysis."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_ai_payload(request, user_id, db)

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
    if file_ids:
        for fid in file_ids:
            try:
                f = await db.files.find_one({"_id": ObjectId(fid), "user_id": user_id, "is_deleted": False})
                txt = await _resolve_ai_text({"file_id": fid}, None, user_id, db)
                docs.append({"id": fid, "name": f["original_filename"] if f else fid, "text": txt})
            except Exception:
                continue
    elif raw_docs:
        docs = raw_docs

    if len(docs) < 2:
        raise HTTPException(status_code=400, detail="At least 2 documents are required for similarity analysis")

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
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

    result = await ai_service.semantic_search(text, query)
    return result


@router.post("/classify")
async def classify_route(request: Request, current_user: dict = Depends(get_current_user)):
    """AI classification of document type and structure."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

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
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

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

    if not text:
        raise HTTPException(status_code=400, detail="Text or file is required")

    result = await ai_service.writing_assistant(text, task=task, custom_instruction=custom_instruction)
    return result


@router.post("/detect-privacy")
async def detect_privacy_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Detect PII and sensitive data for privacy and redaction."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

    result = await ai_service.detect_privacy_and_pii(text)
    return result


@router.post("/quality-check")
async def quality_check_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Comprehensive document quality audit."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

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
        content_type = f.get("content_type", "") or ""
        filename = f.get("original_filename", "") or ""
        if content_type == "application/pdf" or filename.lower().endswith(".pdf") or file_bytes.startswith(b"%PDF-"):
            from services.processing import extract_text_with_pages
            pages_data = extract_text_with_pages(file_bytes)
            text = "\n\n".join([f"=== [Page {p['page']}] ===\n{p['text']}" for p in pages_data])
            if not text.strip():
                text = await ai_service.ocr_pdf(file_bytes, max_pages=10)
        else:
            text = await _resolve_ai_text(body, file_tuple, user_id, db)
    else:
        text = await _resolve_ai_text(body, file_tuple, user_id, db)

    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

    result = await ai_service.ask_pdf(text, question, pages_data=pages_data)
    return {"answer": result}


@router.post("/translate")
async def translate(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    target_language = body.get("target_language", "Spanish")
    text = await _resolve_ai_text(body, file_tuple, user_id, db)

    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

    result = await ai_service.translate_pdf(text, target_language)
    return {"translation": result}


@router.post("/extract-tables")
async def extract_tables(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

    result = await ai_service.extract_tables(text)
    return {"tables": result}


@router.post("/pdf-to-markdown")
async def pdf_to_markdown_ai(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_ai_payload(request, user_id, db)

    text = await _resolve_ai_text(body, file_tuple, user_id, db)
    if not text:
        raise HTTPException(status_code=400, detail="file_id, text, or file upload required")

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
        
        # Heading 1 or 2
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
            # Replace basic markdown bold
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

    if not ocr_text:
        raise HTTPException(status_code=400, detail="OCR text or valid file required")

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

