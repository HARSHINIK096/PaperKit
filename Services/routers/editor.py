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

FONT_MAPPING = {
    "helvetica": "helv",
    "arial": "helv",
    "sans-serif": "helv",
    "times": "tiro",
    "times-roman": "tiro",
    "serif": "tiro",
    "courier": "cour",
    "monospace": "cour",
}

def map_font_name(font_name: str) -> str:
    if not font_name:
        return "helv"
    name_lower = font_name.lower().strip()
    for k, v in FONT_MAPPING.items():
        if k in name_lower:
            return v
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
                font_name = map_font_name(edit.get("font_name", "Helvetica"))
                font_size = float(edit.get("font_size", edit.get("fontSize", 12)))

                color_arr = edit.get("color", [0, 0, 0])
                if isinstance(color_arr, list) and len(color_arr) == 3:
                    r, g, b = float(color_arr[0]), float(color_arr[1]), float(color_arr[2])
                    # Normalize [0-255] RGB values to [0.0-1.0] if needed
                    if r > 1.0 or g > 1.0 or b > 1.0:
                        r, g, b = r / 255.0, g / 255.0, b / 255.0
                else:
                    r, g, b = 0.0, 0.0, 0.0

                # Cleanly redact existing text inside bounding box
                page.add_redact_annot(rect, fill=(1, 1, 1))
                page.apply_redactions()

                # Calculate text baseline position
                # Point baseline in PyMuPDF is y0 + baseline offset
                baseline_y = y0 + font_size * 0.8
                point = fitz.Point(x0, baseline_y)

                if new_text:
                    page.insert_text(
                        point,
                        new_text,
                        fontsize=font_size,
                        fontname=font_name,
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
