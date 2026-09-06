"""
Unit tests for PaperKit PDF Editor Router & Rate Limiter
"""
import os
import json
import pytest
import fitz
from httpx import AsyncClient, ASGITransport
from fastapi import FastAPI
from routers.editor import router as editor_router
from middleware.editor_rate_limiter import DB_PATH, init_db

app = FastAPI()
app.include_router(editor_router, prefix="/api/editor")

@pytest.fixture(autouse=True)
def clean_rate_limit_db():
    """Clear rate limits table before each test."""
    init_db()
    import sqlite3
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM daily_limits")
        conn.commit()

@pytest.mark.asyncio
async def test_editor_limits_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/api/editor/limits")
        assert res.status_code == 200
        data = res.json()
        assert data["remaining"] == 3
        assert data["limit"] == 3

@pytest.mark.asyncio
async def test_apply_pdf_edit_success(sample_pdf_bytes):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        payload = json.dumps({
            "page_number": 1,
            "edits": [
                {
                    "type": "text",
                    "bbox": [72, 72, 300, 100],
                    "new_text": "Modified Text Line",
                    "font_name": "Helvetica",
                    "font_size": 14.0,
                    "color": [255, 0, 0]
                }
            ]
        })
        
        files = {"file": ("test.pdf", sample_pdf_bytes, "application/pdf")}
        data = {"payload": payload}
        
        res = await client.post("/api/editor/edit", files=files, data=data)
        assert res.status_code == 200
        assert res.headers["content-type"] == "application/pdf"
        assert res.headers["x-remaining-edits"] == "2"
        
        # Verify returned PDF contains updated text
        out_doc = fitz.open("pdf", res.content)
        assert out_doc.page_count == 1
        page_text = out_doc[0].get_text()
        assert "Modified Text Line" in page_text
        out_doc.close()

@pytest.mark.asyncio
async def test_editor_rate_limit_blocking(sample_pdf_bytes):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test", cookies={"paperkit_client_id": "test_client_123"}) as client:
        payload = json.dumps({"page_number": 1, "edits": []})
        
        # 1st edit - OK
        res1 = await client.post("/api/editor/edit", files={"file": ("test.pdf", sample_pdf_bytes, "application/pdf")}, data={"payload": payload})
        assert res1.status_code == 200
        assert res1.headers["x-remaining-edits"] == "2"

        # 2nd edit - OK
        res2 = await client.post("/api/editor/edit", files={"file": ("test.pdf", sample_pdf_bytes, "application/pdf")}, data={"payload": payload})
        assert res2.status_code == 200
        assert res2.headers["x-remaining-edits"] == "1"

        # 3rd edit - OK
        res3 = await client.post("/api/editor/edit", files={"file": ("test.pdf", sample_pdf_bytes, "application/pdf")}, data={"payload": payload})
        assert res3.status_code == 200
        assert res3.headers["x-remaining-edits"] == "0"

        # 4th edit - Blocked (429 Too Many Requests)
        res4 = await client.post("/api/editor/edit", files={"file": ("test.pdf", sample_pdf_bytes, "application/pdf")}, data={"payload": payload})
        assert res4.status_code == 429
        assert "Daily free limit reached" in res4.json()["detail"]
