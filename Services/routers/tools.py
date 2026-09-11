import base64
from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile
from database import get_db
from middleware.auth import get_current_user
from services.storage import upload_file, get_file_bytes
from services.processing import (
    merge_pdfs, split_pdf, compress_pdf, estimate_compression,
    rotate_pdf, add_watermark, pdf_to_images, images_to_pdf,
    organize_pdf_pages, get_page_count,
    pdf_to_txt, pdf_to_html, pdf_to_word_fallback, pdf_to_excel_fallback, pdf_to_ppt_fallback,
    word_to_pdf_fallback, excel_to_pdf_fallback, ppt_to_pdf_fallback, html_to_word_bytes,
    protect_pdf, sign_pdf, manage_metadata, redact_pdf_text,
    create_archive_bytes, extract_archive_bytes,
    generate_nup_pdf, generate_booklet_pdf, add_headers_footers_pdf, apply_bates_stamping,
    flatten_pdf_forms, sanitize_image_exif, verify_pdf_checksum,
)
from services.scanner import detect_document_corners, warp_perspective_and_enhance
from config import get_settings
from bson import ObjectId
from datetime import timezone, datetime
from typing import Optional
import io
import json
import pymupdf as fitz

settings = get_settings()
router = APIRouter(prefix="/tools", tags=["tools"])


async def _get_file_bytes(file_id: str, user_id: str, db) -> tuple[bytes, dict]:
    """Fetch file bytes + metadata for authenticated user."""
    if not ObjectId.is_valid(file_id):
        raise HTTPException(status_code=404, detail=f"File {file_id} not found")
    f = await db.files.find_one({"_id": ObjectId(file_id), "user_id": user_id, "is_deleted": False})
    if not f:
        raise HTTPException(status_code=404, detail=f"File {file_id} not found")
    return get_file_bytes(f["storage_url"]), f


async def _save_result(result_bytes: bytes, filename: str, content_type: str, user_id: str, db) -> tuple[str, str]:
    """Save processing result to storage and DB, validating PDF structure and returning (storage_url, sha256_hash)."""
    import hashlib
    
    # Binary PDF Validation
    if content_type == "application/pdf" or filename.lower().endswith(".pdf"):
        if not result_bytes.startswith(b"%PDF-"):
            raise HTTPException(status_code=422, detail="Generated output is not a valid PDF binary.")
        try:
            val_doc = fitz.open("pdf", result_bytes)
            page_count = val_doc.page_count
            val_doc.close()
        except Exception as err:
            raise HTTPException(status_code=422, detail=f"Generated PDF failed structural validation: {err}")
    else:
        page_count = None

    sha256_hash = hashlib.sha256(result_bytes).hexdigest()
    storage = await upload_file(result_bytes, filename, content_type)
    
    doc = {
        "user_id": user_id,
        "original_filename": filename,
        "content_type": content_type,
        "size": len(result_bytes),
        "sha256": sha256_hash,
        "page_count": page_count,
        "storage_url": storage["storage_url"],
        "is_deleted": False,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
    await db.files.insert_one(doc)
    return storage["storage_url"], str(doc["_id"])


async def _log_history(
    user_id: str,
    tool_id: str,
    action: str,
    input_files: list[str],
    output_url: str,
    parameters: dict,
    db,
    *,
    started_at: datetime = None,
    duration_ms: int = None,
    error: str = None,
    status: str = "completed",
):
    """Save user processing history record to MongoDB with full timing & status."""
    out_file = await db.files.find_one({"user_id": user_id, "storage_url": output_url, "is_deleted": False})
    out_file_info = {
        "id":          str(out_file["_id"]) if out_file else "",
        "filename":    out_file["original_filename"] if out_file else output_url.split("/")[-1],
        "size":        out_file["size"] if out_file else 0,
        "storage_url": output_url,
    }

    completed_at = datetime.now(timezone.utc)
    history_doc = {
        "user_id":      user_id,
        "tool_id":      tool_id,
        "action":       action,
        "input_files":  input_files,
        "output_file":  out_file_info,
        "parameters":   parameters,
        "status":       status,
        "started_at":   started_at,
        "completed_at": completed_at,
        "duration_ms":  duration_ms,
        "error":        error,
        "created_at":   datetime.now(timezone.utc),
    }
    await db.history.insert_one(history_doc)


async def _extract_tool_payload(request: Request, user_id: str, db) -> tuple[dict, Optional[tuple[bytes, dict]]]:
    """
    Extracts tool arguments and source file bytes regardless of whether request is JSON or multipart/form-data.
    Returns (params_dict, (file_bytes, file_metadata) or None).
    """
    content_type = request.headers.get("content-type", "")
    params = {}
    file_tuple = None

    if "multipart/form-data" in content_type:
        form = await request.form()
        uploaded_files = []
        for key, val in form.items():
            if isinstance(val, UploadFile):
                content = await val.read()
                storage_url, file_id = await _save_result(content, val.filename or "uploaded_document", val.content_type or "application/octet-stream", user_id, db)
                meta = {"_id": file_id, "original_filename": val.filename, "content_type": val.content_type, "storage_url": storage_url}
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
        file_tuple = await _get_file_bytes(file_id, user_id, db)

    return params, file_tuple


# ── Merge ──────────────────────────────────────────────────────────────────────

@router.post("/merge")
async def merge(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_tool_payload(request, user_id, db)

    file_ids = body.get("file_ids", [])
    if isinstance(file_ids, str):
        try:
            file_ids = json.loads(file_ids)
        except Exception:
            file_ids = [f.strip() for f in file_ids.split(",") if f.strip()]

    options = body.get("options", {})
    if isinstance(options, str):
        try:
            options = json.loads(options)
        except Exception:
            options = {}

    page_size = options.get("page_size", body.get("page_size", "original"))
    margin = options.get("margin", body.get("margin", "none"))

    pdf_bytes_list = []
    input_filenames = []

    uploaded_files = body.get("_uploaded_files", [])
    if uploaded_files and len(uploaded_files) >= 2:
        for data, meta in uploaded_files:
            pdf_bytes_list.append(data)
            input_filenames.append(meta.get("original_filename", "file.pdf"))
    elif file_ids:
        for fid in file_ids:
            data, meta = await _get_file_bytes(fid, user_id, db)
            pdf_bytes_list.append(data)
            input_filenames.append(meta.get("original_filename", "file.pdf"))

    if len(pdf_bytes_list) < 2:
        raise HTTPException(status_code=400, detail="At least 2 files required")

    result = merge_pdfs(pdf_bytes_list, page_size=page_size, margin_type=margin)
    output_filename = "merged.pdf"
    if input_filenames:
        base_stem = input_filenames[0].rsplit(".", 1)[0]
        output_filename = f"{base_stem}_merged.pdf"

    url, _ = await _save_result(result, output_filename, "application/pdf", user_id, db)
    await _log_history(user_id, "merge-pdf", f"Merged {len(pdf_bytes_list)} files into {output_filename}", input_filenames, url, {"page_size": page_size, "margin": margin}, db)

    return {"download_url": url, "size": len(result)}


@router.post("/organize")
async def organize(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id is required")

    pages = body.get("pages", [])
    if isinstance(pages, str):
        try:
            pages = json.loads(pages)
        except Exception:
            pages = []
    tool_id = body.get("tool_id", "organize-pages")

    if not pages:
        raise HTTPException(status_code=400, detail="pages sequence is required")

    src_bytes, meta = file_tuple
    result = organize_pdf_pages(src_bytes, pages)

    old_filename = meta.get("original_filename", "file.pdf")
    stem = old_filename.rsplit(".", 1)[0]
    output_filename = f"{stem}_organized.pdf"

    url, _ = await _save_result(result, output_filename, "application/pdf", user_id, db)
    await _log_history(user_id, tool_id, f"Organized pages of {old_filename}", [old_filename], url, {"pages_count": len(pages)}, db)

    return {"download_url": url, "size": len(result)}


# ── Split ──────────────────────────────────────────────────────────────────────

@router.post("/split")
async def split(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    mode = body.get("mode", "range")
    tool_id = body.get("tool_id", "split-pdf")
    src_bytes, meta = file_tuple

    kwargs = {k: v for k, v in body.items() if k not in ("file_id", "mode", "tool_id", "_uploaded_files")}
    parts = split_pdf(src_bytes, mode, **kwargs)

    original_name = meta.get("original_filename", "file.pdf")
    stem = original_name.rsplit(".", 1)[0]

    if len(parts) == 1:
        url, _ = await _save_result(parts[0], f"{stem}_split.pdf", "application/pdf", user_id, db)
        await _log_history(user_id, tool_id, f"Split {original_name}", [original_name], url, {"mode": mode}, db)
        return {"download_url": url, "parts": 1}

    urls = []
    for i, part in enumerate(parts):
        url, _ = await _save_result(part, f"{stem}_split_part_{i+1}.pdf", "application/pdf", user_id, db)
        urls.append(url)

    if urls:
        await _log_history(user_id, tool_id, f"Split {original_name} into {len(parts)} parts", [original_name], urls[0], {"mode": mode, "parts": len(parts)}, db)

    return {"download_urls": urls, "parts": len(parts)}


# ── Compress ───────────────────────────────────────────────────────────────────

@router.post("/compress")
async def compress(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    quality = body.get("quality", "balanced")
    src_bytes, meta = file_tuple

    result = compress_pdf(src_bytes, quality)
    original_name = meta.get("original_filename", "file.pdf")
    stem = original_name.rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_compressed.pdf", "application/pdf", user_id, db)
    await _log_history(
        user_id,
        "compress-pdf",
        f"Compressed {original_name} ({quality})",
        [original_name],
        url,
        {"quality": quality, "original_size": len(src_bytes), "compressed_size": len(result)},
        db
    )
    return {"download_url": url, "original_size": len(src_bytes), "compressed_size": len(result)}


@router.post("/compress/estimate")
async def estimate_compression_route(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    quality = body.get("quality", "balanced")
    src_bytes, _ = file_tuple
    return estimate_compression(src_bytes, quality)


# ── Convert ────────────────────────────────────────────────────────────────────

EXT_MAP = {
    "word": "docx", "excel": "xlsx", "ppt": "pptx",
    "txt": "txt", "html": "html", "markdown": "md",
    "pdf": "pdf", "image": "jpg",
}

MIME_MAP = {
    "pdf": "application/pdf",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "txt": "text/plain",
    "html": "text/html",
    "md": "text/markdown",
    "jpg": "image/jpeg",
}


@router.post("/convert")
async def convert(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    from_fmt = (body.get("from_format") or body.get("from") or "pdf").lower()
    to_fmt = (body.get("to_format") or body.get("to") or "word").lower()

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    src_bytes, meta = file_tuple

    to_ext = EXT_MAP.get(to_fmt, to_fmt)
    from_ext = EXT_MAP.get(from_fmt, from_fmt)

    try:
        # Route conversions
        if from_fmt == "pdf":
            if to_fmt in ("image", "jpg", "jpeg", "png"):
                images = pdf_to_images(src_bytes)
                if not images:
                    raise HTTPException(status_code=422, detail="Could not convert to images")
                result_bytes = images[0]  # Return first page image
            elif to_fmt == "txt":
                result_bytes = pdf_to_txt(src_bytes)
            elif to_fmt == "html":
                result_bytes = pdf_to_html(src_bytes)
            elif to_fmt == "markdown":
                if settings.groq_api_key or settings.gemini_api_key:
                    from services import ai_service
                    from services.processing import extract_text
                    pdf_text = extract_text(src_bytes)
                    if not pdf_text.strip():
                        md_text = await ai_service.ocr_pdf(src_bytes, max_pages=10)
                    else:
                        md_text = await ai_service.pdf_to_markdown(pdf_text)
                    result_bytes = md_text.encode("utf-8")
                else:
                    result_bytes = pdf_to_txt(src_bytes)
            elif to_fmt == "word":
                result_bytes = pdf_to_word_fallback(src_bytes)
            elif to_fmt == "excel":
                result_bytes = pdf_to_excel_fallback(src_bytes)
            elif to_fmt == "ppt":
                result_bytes = pdf_to_ppt_fallback(src_bytes)
            else:
                raise HTTPException(status_code=400, detail=f"Unsupported target format {to_fmt}")

        elif to_fmt == "pdf":
            if from_fmt in ("image", "jpg", "jpeg", "png", "webp", "bmp"):
                result_bytes = images_to_pdf([src_bytes])
            elif from_fmt == "word":
                result_bytes = word_to_pdf_fallback(src_bytes)
            elif from_fmt == "excel":
                result_bytes = excel_to_pdf_fallback(src_bytes)
            elif from_fmt == "ppt":
                result_bytes = ppt_to_pdf_fallback(src_bytes)
            elif from_fmt == "txt":
                from reportlab.lib.pagesizes import letter
                from reportlab.platypus import SimpleDocTemplate, Paragraph
                from reportlab.lib.styles import getSampleStyleSheet
                pdf_stream = io.BytesIO()
                pdf_doc = SimpleDocTemplate(pdf_stream, pagesize=letter)
                styles = getSampleStyleSheet()
                story = []
                txt_content = src_bytes.decode("utf-8", errors="ignore")
                for line in txt_content.split("\n"):
                    story.append(Paragraph(line if line.strip() else "&nbsp;", styles['Normal']))
                pdf_doc.build(story)
                result_bytes = pdf_stream.getvalue()
            elif from_fmt == "html":
                from reportlab.lib.pagesizes import letter
                from reportlab.platypus import SimpleDocTemplate, Paragraph
                from reportlab.lib.styles import getSampleStyleSheet
                pdf_stream = io.BytesIO()
                pdf_doc = SimpleDocTemplate(pdf_stream, pagesize=letter)
                styles = getSampleStyleSheet()
                story = []
                html_content = src_bytes.decode("utf-8", errors="ignore")
                import re
                clean_text = re.sub('<[^<]+?>', '', html_content)
                for line in clean_text.split("\n"):
                    story.append(Paragraph(line if line.strip() else "&nbsp;", styles['Normal']))
                pdf_doc.build(story)
                result_bytes = pdf_stream.getvalue()
            else:
                raise HTTPException(status_code=400, detail=f"Unsupported source format {from_fmt}")
        else:
            raise HTTPException(status_code=400, detail="Conversion must involve PDF as source or destination")

    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Conversion failed: {str(e)}")

    mime = MIME_MAP.get(to_ext, "application/octet-stream")
    stem = meta.get("original_filename", "file").rsplit(".", 1)[0]
    res_filename = f"{stem}.{to_ext}"
    url, res_file_id = await _save_result(result_bytes, res_filename, mime, user_id, db)

    tool_id = f"{from_fmt}-to-{to_fmt}"
    await _log_history(
        user_id,
        tool_id,
        f"Converted {meta.get('original_filename')} to {to_fmt.upper()}",
        [meta.get("original_filename")],
        url,
        {"from_format": from_fmt, "to_format": to_fmt},
        db
    )

    html_content = ""
    text_content = ""
    if from_fmt == "pdf":
        try:
            html_content = pdf_to_html(src_bytes).decode("utf-8", errors="ignore")
            text_content = pdf_to_txt(src_bytes).decode("utf-8", errors="ignore")
        except Exception:
            pass

    return {
        "file_id": res_file_id,
        "download_url": url,
        "filename": res_filename,
        "size": len(result_bytes),
        "html_content": html_content,
        "text_content": text_content
    }


@router.post("/html-to-word")
async def convert_html_to_word(request: Request, current_user: dict = Depends(get_current_user)):
    """Convert Web Editor HTML or text content directly into Word DOCX format for step-by-step editing pipeline."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, _ = await _extract_tool_payload(request, user_id, db)

    html_content = body.get("html_content") or body.get("text_content") or ""
    filename = body.get("filename", "edited_document.docx")
    if not html_content.strip():
        raise HTTPException(status_code=400, detail="html_content or text_content required")

    docx_bytes = html_to_word_bytes(html_content)
    mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    url, doc_id = await _save_result(docx_bytes, filename, mime, user_id, db)
    return {"file_id": doc_id, "download_url": url, "filename": filename, "size": len(docx_bytes)}


# ── Rotate ─────────────────────────────────────────────────────────────────────

@router.post("/rotate")
async def rotate(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    degrees = int(body.get("degrees", 90))
    pages = body.get("pages")
    if isinstance(pages, str):
        try:
            pages = json.loads(pages)
        except Exception:
            pages = None

    src_bytes, meta = file_tuple
    result = rotate_pdf(src_bytes, degrees, pages)
    stem = meta.get("original_filename", "file.pdf").rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_rotated.pdf", "application/pdf", user_id, db)
    await _log_history(
        user_id,
        "rotate-pdf",
        f"Rotated pages of {meta.get('original_filename')} by {degrees}°",
        [meta.get('original_filename')],
        url,
        {"degrees": degrees, "pages": pages},
        db
    )
    return {"download_url": url}


# ── Watermark ──────────────────────────────────────────────────────────────────

@router.post("/watermark")
async def watermark(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id required")

    text = body.get("text", "CONFIDENTIAL")
    opacity = float(body.get("opacity", 0.3))
    src_bytes, meta = file_tuple

    result = add_watermark(src_bytes, text, opacity)
    stem = meta.get("original_filename", "file.pdf").rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_watermarked.pdf", "application/pdf", user_id, db)
    await _log_history(
        user_id,
        "watermark",
        f"Added watermark '{text}' to {meta.get('original_filename')}",
        [meta.get('original_filename')],
        url,
        {"text": text, "opacity": opacity},
        db
    )
    return {"download_url": url}








# ── PDF Security, Signatures, Metadata, and Redaction ─────────────────────────

@router.post("/protect")
async def protect_pdf_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Encrypt and password-protect PDF with permission settings."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id is required")

    password = body.get("password")
    owner_password = body.get("owner_password")
    allow_print = body.get("allow_print", True)
    allow_copy = body.get("allow_copy", True)
    allow_edit = body.get("allow_edit", True)

    if not password:
        raise HTTPException(status_code=400, detail="password is required")

    pdf_bytes, meta = file_tuple

    result = protect_pdf(
        pdf_bytes,
        user_password=password,
        owner_password=owner_password,
        allow_print=allow_print,
        allow_copy=allow_copy,
        allow_edit=allow_edit,
    )

    old_filename = meta.get("original_filename", "file.pdf")
    stem = old_filename.rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_protected.pdf", "application/pdf", user_id, db)
    await _log_history(user_id, "protect-pdf", f"Password protected {old_filename}", [old_filename], url, {"allow_print": allow_print, "allow_copy": allow_copy}, db)
    return {"download_url": url, "size": len(result)}


@router.post("/sign")
async def sign_pdf_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Place visual digital signatures on PDF pages."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id is required")

    signatures = body.get("signatures", [])
    if isinstance(signatures, str):
        try:
            signatures = json.loads(signatures)
        except Exception:
            signatures = []

    if not signatures:
        raise HTTPException(status_code=400, detail="signatures list is required")

    pdf_bytes, meta = file_tuple

    result = sign_pdf(pdf_bytes, signatures)
    old_filename = meta.get("original_filename", "file.pdf")
    stem = old_filename.rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_signed.pdf", "application/pdf", user_id, db)
    await _log_history(user_id, "digital-signature", f"Digitally signed {old_filename}", [old_filename], url, {"signature_count": len(signatures)}, db)
    return {"download_url": url, "size": len(result)}


@router.get("/geometry/{file_id}")
async def get_pdf_geometry_route(file_id: str, current_user: dict = Depends(get_current_user)):
    """Calculate and return exact real-time page geometry metadata (width_pt, height_pt, width_mm, height_mm, orientation) for a PDF."""
    from services.processing import get_pdf_geometry
    db = get_db()
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(file_id, user_id, db)
    geometry = get_pdf_geometry(pdf_bytes)
    geometry["filename"] = meta.get("original_filename", "document.pdf")
    return geometry


@router.get("/metadata/{file_id}")
async def get_metadata_route(file_id: str, current_user: dict = Depends(get_current_user)):
    """Inspect PDF metadata."""
    db = get_db()
    user_id = str(current_user["_id"])
    pdf_bytes, _ = await _get_file_bytes(file_id, user_id, db)
    _, meta = manage_metadata(pdf_bytes)
    return {"metadata": meta}


@router.post("/metadata")
async def update_metadata_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Update or wipe PDF metadata for privacy."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id is required")

    updates = body.get("updates", {})
    if isinstance(updates, str):
        try:
            updates = json.loads(updates)
        except Exception:
            updates = {}
    wipe_all = body.get("wipe_all", False)

    pdf_bytes, meta = file_tuple

    result, updated_meta = manage_metadata(pdf_bytes, updates=updates, wipe_all=wipe_all)
    old_filename = meta.get("original_filename", "file.pdf")
    stem = old_filename.rsplit(".", 1)[0]
    out_name = f"{stem}_sanitized.pdf" if wipe_all else f"{stem}_metadata.pdf"
    url, _ = await _save_result(result, out_name, "application/pdf", user_id, db)
    action_msg = f"Sanitized metadata in {old_filename}" if wipe_all else f"Updated metadata in {old_filename}"
    await _log_history(user_id, "metadata-manager", action_msg, [old_filename], url, {"wipe_all": wipe_all}, db)
    return {"download_url": url, "metadata": updated_meta, "size": len(result)}


@router.post("/redact")
async def redact_pdf_route(request: Request, current_user: dict = Depends(get_current_user)):
    """Apply irreversible blackouts / redactions to PDF text."""
    db = get_db()
    user_id = str(current_user["_id"])
    body, file_tuple = await _extract_tool_payload(request, user_id, db)

    if not file_tuple:
        raise HTTPException(status_code=400, detail="file or file_id is required")

    terms = body.get("terms", [])
    if isinstance(terms, str):
        try:
            terms = json.loads(terms)
        except Exception:
            terms = [t.strip() for t in terms.split(",") if t.strip()]

    if not terms:
        raise HTTPException(status_code=400, detail="terms list is required")

    pdf_bytes, meta = file_tuple

    result = redact_pdf_text(pdf_bytes, terms)
    old_filename = meta.get("original_filename", "file.pdf")
    stem = old_filename.rsplit(".", 1)[0]
    url, _ = await _save_result(result, f"{stem}_redacted.pdf", "application/pdf", user_id, db)
    await _log_history(user_id, "smart-redaction", f"Redacted {len(terms)} items in {old_filename}", [old_filename], url, {"terms_count": len(terms)}, db)
    return {"download_url": url, "size": len(result)}


@router.get("/history")
async def get_history(
    limit: int = 50,
    skip: int = 0,
    tool_id: str = None,
    status: str = None,
    current_user: dict = Depends(get_current_user),
):
    db      = get_db()
    user_id = str(current_user["_id"])
    cursor  = db.history.find({"user_id": user_id}).sort([("created_at", -1)]).skip(skip).limit(limit)
    items   = []
    async for h in cursor:
        # Filter server-side if query params given (mock DB doesn't support complex queries)
        if tool_id and h.get("tool_id") != tool_id:
            continue
        if status and h.get("status") != status:
            continue

        def _fmt(v):
            if isinstance(v, datetime):
                return v.isoformat()
            return v

        items.append({
            "id":           str(h["_id"]),
            "tool_id":      h.get("tool_id", ""),
            "action":       h.get("action", ""),
            "operation":    h.get("tool_id", ""),
            "input_files":  h.get("input_files", []),
            "output_file":  h.get("output_file"),
            "parameters":   h.get("parameters", {}),
            "status":       h.get("status", "completed"),
            "duration_ms":  h.get("duration_ms"),
            "error":        h.get("error"),
            "created_at":   _fmt(h.get("created_at")),
            "started_at":   _fmt(h.get("started_at")),
            "completed_at": _fmt(h.get("completed_at")),
        })
    return items


_REGISTRY_CACHE = None

@router.get("/registry")
async def get_tools_registry():
    global _REGISTRY_CACHE
    if _REGISTRY_CACHE is not None:
        return _REGISTRY_CACHE

    ai_available = bool(settings.groq_api_key or settings.gemini_api_key)
    tools = [
        # Organize Category
        {
            "toolId": "merge-pdf",
            "name": "Merge PDF",
            "description": "Combine multiple PDF files into one document.",
            "icon": "merge-pdf",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/merge",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["multi-file-merge", "page-reorder"]
        },
        {
            "toolId": "split-pdf",
            "name": "Split PDF",
            "description": "Extract specific page ranges or split each page into separate PDFs.",
            "icon": "split-pdf",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/split",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["split-by-range", "split-by-n-pages", "extract-pages"]
        },
        {
            "toolId": "extract-pages",
            "name": "Extract Pages",
            "description": "Extract specific pages from a PDF document.",
            "icon": "extract-pages",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/extract-pages",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["page-extraction"]
        },
        {
            "toolId": "remove-pages",
            "name": "Remove Pages",
            "description": "Remove unwanted pages from your PDF file.",
            "icon": "remove-pages",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/remove-pages",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["page-deletion"]
        },
        {
            "toolId": "reorder-pages",
            "name": "Reorder Pages",
            "description": "Drag and drop to rearrange PDF page order.",
            "icon": "reorder-pages",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/reorder-pages",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["page-reordering"]
        },
        {
            "toolId": "rotate-pdf",
            "name": "Rotate PDF",
            "description": "Rotate PDF pages clockwise or counter-clockwise.",
            "icon": "rotate-pdf",
            "category": "Organize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/rotate",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["rotate-all-pages", "rotate-specific-pages"]
        },
        # Convert to PDF Category
        {
            "toolId": "word-to-pdf",
            "name": "Word to PDF",
            "description": "Convert DOCX/DOC files to PDF.",
            "icon": "word-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".doc", ".docx"],
            "route": "/tools/convert?from=word&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["batch-convert", "high-fidelity-layout"]
        },
        {
            "toolId": "excel-to-pdf",
            "name": "Excel to PDF",
            "description": "Convert XLSX/XLS files to PDF.",
            "icon": "excel-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".xls", ".xlsx"],
            "route": "/tools/convert?from=excel&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["sheet-paging", "formula-rendering"]
        },
        {
            "toolId": "ppt-to-pdf",
            "name": "PPT to PDF",
            "description": "Convert PPTX/PPT files to PDF.",
            "icon": "ppt-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".ppt", ".pptx"],
            "route": "/tools/convert?from=ppt&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["slide-scaling", "notes-rendering"]
        },
        {
            "toolId": "image-to-pdf",
            "name": "Image to PDF",
            "description": "Convert JPEG, PNG, or WEBP images to PDF.",
            "icon": "image-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".jpg", ".jpeg", ".png", ".gif", ".webp"],
            "route": "/tools/convert?from=image&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["multi-image-pdf", "auto-rotation"]
        },
        {
            "toolId": "txt-to-pdf",
            "name": "TXT to PDF",
            "description": "Convert plain text files to PDF.",
            "icon": "txt-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".txt"],
            "route": "/tools/convert?from=txt&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["utf8-encoding", "font-customization"]
        },
        {
            "toolId": "html-to-pdf",
            "name": "HTML to PDF",
            "description": "Convert HTML documents to PDF.",
            "icon": "html-to-pdf",
            "category": "Convert to PDF",
            "supportedFormats": [".html", ".htm"],
            "route": "/tools/convert?from=html&to=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["layout-preservation"]
        },
        # Convert from PDF Category
        {
            "toolId": "pdf-to-word",
            "name": "PDF to Word",
            "description": "Convert PDF files back to editable Word documents.",
            "icon": "pdf-to-word",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=word",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["layout-preservation", "text-extraction", "ocr"]
        },
        {
            "toolId": "pdf-to-excel",
            "name": "PDF to Excel",
            "description": "Convert PDF tables into XLSX format.",
            "icon": "pdf-to-excel",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=excel",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["table-detection", "multi-sheet-output", "ocr"]
        },
        {
            "toolId": "pdf-to-ppt",
            "name": "PDF to PPT",
            "description": "Convert PDF files back to PowerPoint presentations.",
            "icon": "pdf-to-ppt",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=ppt",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["layout-preservation", "slide-generation"]
        },
        {
            "toolId": "pdf-to-image",
            "name": "PDF to Image",
            "description": "Extract pages from a PDF as separate images.",
            "icon": "pdf-to-image",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=image",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["dpi-selection", "jpeg-png-formats"]
        },
        {
            "toolId": "pdf-to-txt",
            "name": "PDF to TXT",
            "description": "Extract raw text from PDF files.",
            "icon": "pdf-to-txt",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=txt",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["text-extraction"]
        },
        {
            "toolId": "pdf-to-html",
            "name": "PDF to HTML",
            "description": "Convert PDF layout to raw HTML.",
            "icon": "pdf-to-html",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=html",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["layout-preservation"]
        },
        {
            "toolId": "pdf-to-markdown",
            "name": "PDF to Markdown",
            "description": "Convert PDF text structure to Markdown formatted text.",
            "icon": "pdf-to-markdown",
            "category": "Convert from PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/convert?from=pdf&to=markdown",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["ai-assisted", "semantic-formatting"]
        },
        # Optimize PDF Category
        {
            "toolId": "compress-pdf",
            "name": "Compress PDF",
            "description": "Reduce file size of your PDF while retaining quality.",
            "icon": "compress-pdf",
            "category": "Optimize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/compress",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["multiple-compression-profiles", "compression-estimation"]
        },
        {
            "toolId": "scan-to-pdf",
            "name": "Scan to PDF",
            "description": "Scan documents using your camera and save directly as PDF.",
            "icon": "scan-to-pdf",
            "category": "Optimize PDF",
            "supportedFormats": [],
            "route": "/scanner?mode=pdf",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["camera-scan", "pdf-output"]
        },

        {
            "toolId": "watermark",
            "name": "Watermark",
            "description": "Overlay a text or image watermark onto PDF pages.",
            "icon": "watermark",
            "category": "Optimize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/watermark",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["text-watermarks", "opacity-settings", "custom-rotation"]
        },
        {
            "toolId": "organize-pages",
            "name": "Organize Pages",
            "description": "Rotate, reorder, and remove pages in your PDF.",
            "icon": "organize-pages",
            "category": "Optimize PDF",
            "supportedFormats": [".pdf"],
            "route": "/tools/organize-pages",
            "availability": {"available": True, "reason": ""},
            "capabilities": ["visual-management", "drag-reorder", "delete-pages", "rotate-pages"]
        },
        # AI Tools Category
        {
            "toolId": "summarize-pdf",
            "name": "Summarize PDF",
            "description": "Generate a concise summary of a PDF's contents using AI.",
            "icon": "summarize-pdf",
            "category": "AI Tools",
            "supportedFormats": [".pdf"],
            "route": "/ai/summarize",
            "availability": {"available": ai_available, "reason": "" if ai_available else "Gemini API key is not configured on the server"},
            "capabilities": ["key-insights", "multi-lingual-summary"]
        },
        {
            "toolId": "ask-pdf",
            "name": "Ask PDF",
            "description": "Interact with your PDF via an AI-powered conversational agent.",
            "icon": "ask-pdf",
            "category": "AI Tools",
            "supportedFormats": [".pdf"],
            "route": "/ai/ask",
            "availability": {"available": ai_available, "reason": "" if ai_available else "Gemini API key is not configured on the server"},
            "capabilities": ["semantic-search", "citation-reference"]
        },
        {
            "toolId": "translate-pdf",
            "name": "Translate PDF",
            "description": "Translate the content of your PDF to another language using AI.",
            "icon": "translate-pdf",
            "category": "AI Tools",
            "supportedFormats": [".pdf"],
            "route": "/ai/translate",
            "availability": {"available": ai_available, "reason": "" if ai_available else "Gemini API key is not configured on the server"},
            "capabilities": ["auto-language-detection", "preserves-original-layout"]
        },
        {
            "toolId": "extract-tables",
            "name": "Extract Tables",
            "description": "Automatically detect and extract tables from a PDF using AI.",
            "icon": "extract-tables",
            "category": "AI Tools",
            "supportedFormats": [".pdf"],
            "route": "/ai/extract-tables",
            "availability": {"available": ai_available, "reason": "" if ai_available else "Gemini API key is not configured on the server"},
            "capabilities": ["smart-detection", "csv-download"]
        },
    ]
    _REGISTRY_CACHE = tools
    return tools


# ── Smart Scanner ──────────────────────────────────────────────────────────────

@router.post("/detect-document")
async def detect_document(body: dict, current_user: dict = Depends(get_current_user)):
    image_b64 = body.get("image")
    if not image_b64:
        raise HTTPException(status_code=400, detail="image (base64 string) is required")

    try:
        # Strip header if present e.g. "data:image/jpeg;base64,..."
        if "," in image_b64:
            image_b64 = image_b64.split(",", 1)[1]
        img_bytes = base64.b64decode(image_b64)
        corners = detect_document_corners(img_bytes)
        return {"corners": corners}
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Failed to detect document: {str(e)}")


@router.post("/process-scan")
async def process_scan(body: dict, current_user: dict = Depends(get_current_user)):
    image_b64 = body.get("image")
    corners = body.get("corners")
    mode = body.get("mode", "document")
    filename = body.get("filename", "scan.jpg")

    if not image_b64:
        raise HTTPException(status_code=400, detail="image (base64 string) is required")
    if not corners or len(corners) != 4:
        raise HTTPException(status_code=400, detail="corners must contain exactly 4 points")

    try:
        if "," in image_b64:
            image_b64 = image_b64.split(",", 1)[1]
        img_bytes = base64.b64decode(image_b64)
        
        # Run real OpenCV perspective warping & enhance
        result_bytes = warp_perspective_and_enhance(img_bytes, corners, mode)
        
        # Save results as a real asset
        db = get_db()
        user_id = str(current_user["_id"])
        url = await _save_result(result_bytes, filename, "image/jpeg", user_id, db)
        
        # Get the newly inserted file doc to return full details
        file_doc = await db.files.find_one({
            "user_id": user_id,
            "storage_url": url,
            "is_deleted": False
        })
        
        if not file_doc:
            raise HTTPException(status_code=500, detail="Saved scan file could not be retrieved")

        return {
            "_id": str(file_doc["_id"]),
            "original_filename": file_doc["original_filename"],
            "content_type": file_doc["content_type"],
            "size": file_doc["size"],
            "created_at": file_doc["created_at"].isoformat() if isinstance(file_doc["created_at"], datetime) else str(file_doc["created_at"]),
            "storage_url": file_doc["storage_url"],
            "thumbnail_url": file_doc["storage_url"]
        }
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Failed to process scan: {str(e)}")


from fastapi.responses import FileResponse, Response
from pydantic import BaseModel

class ArchiveCreateRequest(BaseModel):
    file_ids: list[str]
    format_type: str = "zip"
    password: Optional[str] = None
    output_name: Optional[str] = "archive"

class ArchiveExtractRequest(BaseModel):
    file_id: str
    password: Optional[str] = None


@router.post("/archive/create")
async def create_archive_endpoint(
    req: ArchiveCreateRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Creates a ZIP, TAR, or TAR.GZ archive from input files with optional password encryption."""
    if not req.file_ids:
        raise HTTPException(status_code=400, detail="file_ids list cannot be empty")

    user_id = str(current_user["_id"])
    files_data = []

    for fid in req.file_ids:
        file_bytes, fdoc = await _get_file_bytes(fid, user_id, db)
        fname = fdoc.get("original_filename", f"file_{fid}")
        files_data.append((fname, file_bytes))

    archive_bytes, out_fname, mime = create_archive_bytes(
        files=files_data,
        format_type=req.format_type,
        password=req.password,
    )

    clean_name = req.output_name.strip() if req.output_name else "archive"
    if not clean_name.endswith(out_fname[out_fname.rfind("."):]):
        out_fname = f"{clean_name}{out_fname[out_fname.rfind('.'):]}"

    storage_url, file_id = await _save_result(
        archive_bytes,
        out_fname,
        mime,
        user_id,
        db,
    )

    return {
        "file_id": file_id,
        "storage_url": storage_url,
        "filename": out_fname,
        "content_type": mime,
        "size": len(archive_bytes),
    }


@router.post("/archive/extract")
async def extract_archive_endpoint(
    req: ArchiveExtractRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Extracts files from an archive (ZIP, TAR, GZ, 7Z, RAR) with optional password decryption."""
    user_id = str(current_user["_id"])
    archive_bytes, fdoc = await _get_file_bytes(req.file_id, user_id, db)
    archive_fname = fdoc.get("original_filename", "archive.zip")

    try:
        extracted = extract_archive_bytes(
            archive_bytes,
            archive_fname,
            password=req.password,
        )

        extracted_results = []
        for fname, fbytes in extracted:
            content_type = "application/octet-stream"
            if fname.lower().endswith(".pdf"): content_type = "application/pdf"
            elif fname.lower().endswith(".png"): content_type = "image/png"
            elif fname.lower().endswith((".jpg", ".jpeg")): content_type = "image/jpeg"
            elif fname.lower().endswith(".txt"): content_type = "text/plain"

            s_url, f_id = await _save_result(fbytes, fname, content_type, user_id, db)
            extracted_results.append({
                "file_id": f_id,
                "filename": fname,
                "storage_url": s_url,
                "size": len(fbytes),
            })

        return {
            "archive_filename": archive_fname,
            "extracted_count": len(extracted_results),
            "files": extracted_results,
        }
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Archive extraction failed: {str(e)}")


class NUpRequest(BaseModel):
    file_id: str
    pages_per_sheet: int = 2

class HeaderFooterRequest(BaseModel):
    file_id: str
    header_text: Optional[str] = ""
    footer_text: Optional[str] = ""
    show_page_numbers: bool = True

class BatesRequest(BaseModel):
    file_id: str
    prefix: Optional[str] = "BATES-"
    start_number: int = 1


@router.post("/pdf/nup")
async def nup_pdf_endpoint(req: NUpRequest, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(req.file_id, user_id, db)
    out_bytes = generate_nup_pdf(pdf_bytes, req.pages_per_sheet)
    s_url, f_id = await _save_result(out_bytes, f"nup_{req.pages_per_sheet}_" + meta.get("original_filename", "doc.pdf"), "application/pdf", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/pdf/booklet")
async def booklet_pdf_endpoint(file_id: str, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(file_id, user_id, db)
    out_bytes = generate_booklet_pdf(pdf_bytes)
    s_url, f_id = await _save_result(out_bytes, "booklet_" + meta.get("original_filename", "doc.pdf"), "application/pdf", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/pdf/headers")
async def headers_footers_endpoint(req: HeaderFooterRequest, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(req.file_id, user_id, db)
    out_bytes = add_headers_footers_pdf(pdf_bytes, req.header_text or "", req.footer_text or "", req.show_page_numbers)
    s_url, f_id = await _save_result(out_bytes, "numbered_" + meta.get("original_filename", "doc.pdf"), "application/pdf", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/pdf/bates")
async def bates_stamping_endpoint(req: BatesRequest, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(req.file_id, user_id, db)
    out_bytes = apply_bates_stamping(pdf_bytes, req.prefix or "BATES-", req.start_number)
    s_url, f_id = await _save_result(out_bytes, "bates_" + meta.get("original_filename", "doc.pdf"), "application/pdf", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/pdf/flatten")
async def flatten_forms_endpoint(file_id: str, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, meta = await _get_file_bytes(file_id, user_id, db)
    out_bytes = flatten_pdf_forms(pdf_bytes)
    s_url, f_id = await _save_result(out_bytes, "flattened_" + meta.get("original_filename", "doc.pdf"), "application/pdf", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/image/exif-sanitize")
async def sanitize_exif_endpoint(file_id: str, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    img_bytes, meta = await _get_file_bytes(file_id, user_id, db)
    clean_bytes = sanitize_image_exif(img_bytes)
    s_url, f_id = await _save_result(clean_bytes, "clean_" + meta.get("original_filename", "image.jpg"), "image/jpeg", user_id, db)
    return {"file_id": f_id, "storage_url": s_url}


@router.post("/checksum/verify")
async def verify_checksum_endpoint(file_id: str, current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    user_id = str(current_user["_id"])
    pdf_bytes, _ = await _get_file_bytes(file_id, user_id, db)
    res = verify_pdf_checksum(pdf_bytes)
    return res


