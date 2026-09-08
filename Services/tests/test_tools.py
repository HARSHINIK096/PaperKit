"""PDF Manipulation and Core Tools Test Suite"""
import pytest
from services.processing import get_page_count


@pytest.mark.asyncio
async def test_merge_pdfs(client, seeded_file, sample_pdf_bytes, auth_headers):
    """POST /tools/merge merges multiple PDF files into one."""
    file_id_1 = str(seeded_file["_id"])
    
    # Upload second file
    files = {"file": ("doc2.pdf", sample_pdf_bytes, "application/pdf")}
    up_resp = await client.post("/files/upload", files=files, headers=auth_headers)
    file_id_2 = up_resp.json()["_id"]

    resp = await client.post(
        "/tools/merge",
        json={"file_ids": [file_id_1, file_id_2]},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "download_url" in data


@pytest.mark.asyncio
async def test_organize_pdf(client, seeded_file, auth_headers):
    """POST /tools/organize rearranges and rotates pages in a PDF."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/organize",
        json={"file_id": file_id, "pages": [{"index": 0, "rotation": 90}]},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_split_pdf(client, seeded_file, auth_headers):
    """POST /tools/split splits or extracts pages from a PDF."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/split",
        json={"file_id": file_id, "mode": "all"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "download_url" in data or "download_urls" in data


@pytest.mark.asyncio
async def test_rotate_pdf(client, seeded_file, auth_headers):
    """POST /tools/rotate rotates specified PDF pages."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/rotate",
        json={"file_id": file_id, "degrees": 90},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_watermark_pdf(client, seeded_file, auth_headers):
    """POST /tools/watermark applies text watermark to document."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/watermark",
        json={"file_id": file_id, "text": "CONFIDENTIAL", "opacity": 0.3},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_compress_pdf(client, seeded_file, auth_headers):
    """POST /tools/compress optimizes PDF file size."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/compress",
        json={"file_id": file_id, "quality": "balanced"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_protect_pdf(client, seeded_file, auth_headers):
    """POST /tools/protect password-protects a PDF."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/protect",
        json={"file_id": file_id, "password": "SafePassword123!"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_sign_pdf(client, seeded_file, auth_headers):
    """POST /tools/sign places visual digital signatures on PDF pages."""
    file_id = str(seeded_file["_id"])
    signatures = [
        {
            "page": 0,
            "x": 72,
            "y": 100,
            "width": 120,
            "height": 50,
            "image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
        }
    ]
    resp = await client.post(
        "/tools/sign",
        json={"file_id": file_id, "signatures": signatures},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()


@pytest.mark.asyncio
async def test_pdf_metadata_get_and_update(client, seeded_file, auth_headers):
    """GET /tools/metadata/{id} and POST /tools/metadata."""
    file_id = str(seeded_file["_id"])
    # 1. Read
    resp_get = await client.get(f"/tools/metadata/{file_id}", headers=auth_headers)
    assert resp_get.status_code == 200
    assert "metadata" in resp_get.json()

    # 2. Update
    resp_update = await client.post(
        "/tools/metadata",
        json={"file_id": file_id, "updates": {"title": "PaperKit Automated Title"}},
        headers=auth_headers,
    )
    assert resp_update.status_code == 200
    assert "download_url" in resp_update.json()


@pytest.mark.asyncio
async def test_redact_pdf(client, seeded_file, auth_headers):
    """POST /tools/redact applies text blackouts."""
    file_id = str(seeded_file["_id"])
    resp = await client.post(
        "/tools/redact",
        json={"file_id": file_id, "terms": ["Document"]},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "download_url" in resp.json()
