"""
PaperKit PDF Editor Router
Handles in-place PDF text and image object edits, redacting original bounding boxes
and overlaying new elements via PyMuPDF (fitz), protected by a 3 edit/day rate limiter.
"""
import os
import json
import base64
import fitz  # PyMuPDF
from typing import Optional, List
from fastapi import APIRouter, Request, Response, UploadFile, File, Form, HTTPException, status
from fastapi.responses import Response as FastAPIResponse

from middleware.editor_rate_limiter import (
    get_client_key,
    get_remaining_edits,
    enforce_editor_rate_limit,
    DAILY_LIMIT
)
from database import get_db

router = APIRouter()

def resolve_pymupdf_font(font_name: str, is_bold: bool = False, is_italic: bool = False) -> str:
    """Resolve font family + weight/style into standard PyMuPDF 14 base fonts."""
    fn_lower = (font_name or "").lower()
    is_bold = is_bold or any(b in fn_lower for b in ["bold", "black", "heavy", "medium", "semibold", "tibo", "hebo", "cobo"])
    is_italic = is_italic or any(it in fn_lower for it in ["italic", "oblique", "slanted", "tiit", "heit", "coit"])

    if any(k in fn_lower for k in ["times", "serif", "roman", "georgia", "cambria", "garamond", "minion", "tiro"]):
        if is_bold and is_italic:
            return "tibi"
        elif is_bold:
            return "tibo"
        elif is_italic:
            return "tiit"
        else:
            return "tiro"
    elif any(k in fn_lower for k in ["courier", "mono", "consolas", "menlo", "code", "cour"]):
        if is_bold and is_italic:
            return "cobi"
        elif is_bold:
            return "cobo"
        elif is_italic:
            return "coit"
        else:
            return "cour"
    else: # Helvetica / Arial / Sans-serif / default
        if is_bold and is_italic:
            return "hebi"
        elif is_bold:
            return "hebo"
        elif is_italic:
            return "heit"
        else:
            return "helv"

@router.get("/limits")
async def get_editor_limits(request: Request, response: Response):
    """Check remaining PDF edits for current client today."""
    client_key = get_client_key(request, response)
    remaining, limit = get_remaining_edits(client_key)
    return {
        "remaining": remaining,
        "limit": limit,
        "resets_at": "midnight UTC"
    }

@router.post("/edit")
async def apply_pdf_in_place_edits(
    request: Request,
    response: Response,
    file: Optional[UploadFile] = File(None),
    file_id: Optional[str] = Form(None),
    payload: str = Form(...)
):
    """
    Apply in-place text replacement and image overlay edits on a PDF file.
    Payload format:
    {
       "page_number": 1, // 1-indexed or 0-indexed page number
       "edits": [
          {
             "type": "text",
             "bbox": [x0, y0, x1, y1],
             "new_text": "Updated text",
             "font_name": "Helvetica",
             "font_size": 12.0,
             "color": [0, 0, 0]
          },
          {
             "type": "image",
             "bbox": [x0, y0, x1, y1],
             "new_image_base64": "data:image/png;base64,..."
          }
       ]
    }
    Can also accept top-level list of page edit objects or single edit object.
    """
    # 1. Enforce rate limit
    client_key, remaining = enforce_editor_rate_limit(request, response)

    # 2. Retrieve PDF bytes
    pdf_bytes: bytes = b""
    filename: str = "edited_document.pdf"

    if file and file.filename:
        pdf_bytes = await file.read()
        filename = file.filename
    elif file_id:
        db = get_db()
        if db is not None:
            from bson import ObjectId
            from services.storage import LOCAL_STORAGE_DIR
            query_id = ObjectId(file_id) if ObjectId.is_valid(file_id) else file_id
            file_doc = await db.files.find_one({"_id": query_id})
            if file_doc:
                filename = file_doc.get("original_filename", "edited_document.pdf")
                rel_url = file_doc.get("storage_url", "")
                disk_path = os.path.join(LOCAL_STORAGE_DIR, os.path.basename(rel_url))
                if os.path.exists(disk_path):
                    with open(disk_path, "rb") as f:
                        pdf_bytes = f.read()

    if not pdf_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid PDF file uploaded or file_id provided."
        )

    # 3. Parse edit operations payload
    try:
        raw_payload = json.loads(payload)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid JSON payload: {e}"
        )

    pages_payload = raw_payload if isinstance(raw_payload, list) else [raw_payload]

    # 4. Open PDF stream with PyMuPDF
    try:
        doc = fitz.open("pdf", pdf_bytes)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to parse PDF document: {e}"
        )

    # 5. Process edits page by page using redact-and-overlay strategy
    for page_entry in pages_payload:
        if not isinstance(page_entry, dict):
            continue

        raw_pg_num = page_entry.get("page_number", page_entry.get("page", 1))
        # Handle 1-indexed vs 0-indexed page numbers safely
        pg_idx = int(raw_pg_num)
        if pg_idx >= 1 and pg_idx <= doc.page_count:
            pg_idx = pg_idx - 1  # convert 1-indexed to 0-indexed
        elif pg_idx < 0 or pg_idx >= doc.page_count:
            pg_idx = 0

        page = doc[pg_idx]
        edits_list = page_entry.get("edits", [])
        if not isinstance(edits_list, list):
            continue

        # Separate text redaction and image overlay operations
        for edit in edits_list:
            if not isinstance(edit, dict):
                continue

            edit_type = edit.get("type", "text")
            bbox = edit.get("bbox", [])
            if not bbox or len(bbox) < 4:
                continue

            x0, y0, x1, y1 = [float(v) for v in bbox[:4]]
            rect = fitz.Rect(x0, y0, x1, y1)

            if edit_type == "text":
                new_text = edit.get("new_text", edit.get("text", ""))

                # Extract original font attributes directly from PDF span in clip rect (slightly expanded for sub-pixel boundary tolerances)
                search_rect = fitz.Rect(x0 - 3, y0 - 3, x1 + 3, y1 + 3)
                clip_dict = page.get_text("dict", clip=search_rect)
                orig_spans = []
                for b in clip_dict.get("blocks", []):
                    for l in b.get("lines", []):
                        for s in l.get("spans", []):
                            orig_spans.append(s)

                orig_span = orig_spans[0] if orig_spans else None

                target_font_name = edit.get("raw_font_name") or edit.get("font_name") or (orig_span.get("font") if orig_span else "Helvetica")
                is_bold = edit.get("is_bold", False)
                is_italic = edit.get("is_italic", False)

                if orig_span:
                    flags = orig_span.get("flags", 0)
                    orig_font_name = orig_span.get("font", "").lower()
                    is_bold = is_bold or bool(flags & 16) or any(b in orig_font_name for b in ["bold", "black", "heavy", "medium"])
                    is_italic = is_italic or bool(flags & 2) or any(it in orig_font_name for it in ["italic", "oblique"])

                font_code = resolve_pymupdf_font(target_font_name, is_bold=is_bold, is_italic=is_italic)
                font_size = float(edit.get("font_size") or (orig_span.get("size") if orig_span else 12.0))

                # Color resolution: preserve original color if not customized
                color_arr = edit.get("color", [0, 0, 0])
                if (color_arr == [0, 0, 0] or not color_arr) and orig_span and "color" in orig_span and orig_span["color"] != 0:
                    c_int = int(orig_span["color"])
                    r = ((c_int >> 16) & 255) / 255.0
                    g = ((c_int >> 8) & 255) / 255.0
                    b = (c_int & 255) / 255.0
                elif isinstance(color_arr, list) and len(color_arr) == 3:
                    r, g, b = float(color_arr[0]), float(color_arr[1]), float(color_arr[2])
                    if r > 1.0 or g > 1.0 or b > 1.0:
                        r, g, b = r / 255.0, g / 255.0, b / 255.0
                else:
                    r, g, b = 0.0, 0.0, 0.0

                # Cleanly redact existing text inside bounding box
                page.add_redact_annot(rect, fill=(1, 1, 1))
                page.apply_redactions()

                # Calculate text baseline position: use original baseline if available
                if orig_span and "origin" in orig_span:
                    baseline_point = fitz.Point(orig_span["origin"][0], orig_span["origin"][1])
                else:
                    baseline_point = fitz.Point(x0, y0 + font_size * 0.8)

                if new_text:
                    page.insert_text(
                        baseline_point,
                        new_text,
                        fontsize=font_size,
                        fontname=font_code,
                        color=(r, g, b)
                    )

            elif edit_type == "image":
                new_img_b64 = edit.get("new_image_base64", edit.get("image_base64", ""))
                if new_img_b64:
                    if "," in new_img_b64:
                        new_img_b64 = new_img_b64.split(",", 1)[1]
                    try:
                        img_bytes = base64.b64decode(new_img_b64)
                        page.insert_image(rect, stream=img_bytes)
                    except Exception as img_err:
                        print(f"[PDF Editor] Failed to overlay image: {img_err}")

    # 6. Stream compiled PDF back as file download
    out_pdf_bytes = doc.tobytes(garbage=4, deflate=True)
    doc.close()

    output_filename = f"edited_{os.path.basename(filename)}"
    headers = {
        "Content-Disposition": f'attachment; filename="{output_filename}"',
        "X-Remaining-Edits": str(remaining),
        "Access-Control-Expose-Headers": "Content-Disposition, X-Remaining-Edits"
    }

    return FastAPIResponse(
        content=out_pdf_bytes,
        media_type="application/pdf",
        headers=headers
    )
