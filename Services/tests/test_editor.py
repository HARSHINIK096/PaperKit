"""PDF In-Place Object Editor Test Suite"""
import pytest
import json


@pytest.mark.asyncio
async def test_editor_limits(client):
    """GET /api/editor/limits returns remaining edit quota."""
    resp = await client.get("/api/editor/limits")
    assert resp.status_code == 200
    data = resp.json()
    assert "remaining" in data
    assert "limit" in data
    assert data["limit"] == 3


@pytest.mark.asyncio
async def test_editor_apply_text_edit(client, sample_pdf_bytes):
    """POST /api/editor/edit modifies text block in-place on target page."""
    payload = {
        "page_number": 1,
        "edits": [
            {
                "type": "text",
                "bbox": [72, 100, 300, 120],
                "new_text": "Updated Document Heading",
                "font_name": "Helvetica",
                "font_size": 16.0,
                "color": [0, 0, 0],
            }
        ],
    }
    files = {"file": ("document.pdf", sample_pdf_bytes, "application/pdf")}
    resp = await client.post(
        "/api/editor/edit",
        files=files,
        data={"payload": json.dumps(payload)},
    )
    assert resp.status_code == 200
    assert resp.headers.get("content-type") == "application/pdf"
    assert len(resp.content) > 0


@pytest.mark.asyncio
async def test_editor_invalid_payload(client, sample_pdf_bytes):
    """POST /api/editor/edit rejects invalid JSON payload."""
    files = {"file": ("document.pdf", sample_pdf_bytes, "application/pdf")}
    resp = await client.post(
        "/api/editor/edit",
        files=files,
        data={"payload": "invalid-json-structure"},
    )
    assert resp.status_code == 400
