"""File Management, Upload and Storage Test Suite"""
import pytest
from bson import ObjectId


@pytest.mark.asyncio
async def test_upload_single_file(client, sample_pdf_bytes, auth_headers):
    """POST /files/upload saves file and creates database record."""
    files = {"file": ("my_document.pdf", sample_pdf_bytes, "application/pdf")}
    resp = await client.post("/files/upload", files=files, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "_id" in data
    assert data["original_filename"] == "my_document.pdf"
    assert data["content_type"] == "application/pdf"


@pytest.mark.asyncio
async def test_list_files(client, seeded_file, auth_headers):
    """GET /files returns uploaded files list."""
    resp = await client.get("/files", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert isinstance(data["items"], list)
    assert len(data["items"]) >= 1


@pytest.mark.asyncio
async def test_download_file(client, seeded_file, auth_headers):
    """GET /files/{id}/download streams the file binary."""
    file_id = str(seeded_file["_id"])
    resp = await client.get(f"/files/{file_id}/download", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.content) > 0


@pytest.mark.asyncio
async def test_delete_file(client, seeded_file, auth_headers):
    """DELETE /files/{id} soft-deletes file."""
    file_id = str(seeded_file["_id"])
    resp = await client.delete(f"/files/{file_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["message"] == "File deleted"


@pytest.mark.asyncio
async def test_guest_cleanup_expired_files(db):
    """Verify cleanup_expired_guest_files purges old guest uploads."""
    from services.storage import cleanup_expired_guest_files
    cleaned = await cleanup_expired_guest_files(db, max_age_hours=0)
    assert isinstance(cleaned, int)
