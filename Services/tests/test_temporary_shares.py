"""Comprehensive integration tests for 10-Minute Encrypted Temporary File Sharing."""
import pytest
import io
import os
from datetime import datetime, timezone, timedelta
from httpx import AsyncClient, ASGITransport
from main import app
from database import get_db
from routers.temporary_shares import TEMP_SHARES_DIR, cleanup_expired_temporary_shares


@pytest.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_create_and_download_temporary_share(async_client):
    file_content = b"Confidential Financial Audit 2026 - Top Secret"
    password = "MySafePassword123!"

    # 1. Create temporary share
    files = {"file": ("audit_report.pdf", io.BytesIO(file_content), "application/pdf")}
    data = {"password": password}

    res = await async_client.post("/temporary-shares", files=files, data=data)
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["success"] is True
    assert "share_id" in body
    assert body["original_filename"] == "audit_report.pdf"
    assert body["file_size"] == len(file_content)
    assert body["expires_in_seconds"] == 600
    assert "share_url" in body

    share_id = body["share_id"]
    expires_at = datetime.fromisoformat(body["expires_at"])
    now = datetime.now(timezone.utc)
    # Expiration is ~10 minutes from now (within 5 seconds tolerance)
    assert 590 <= (expires_at - now).total_seconds() <= 610

    # 2. Verify encrypted at rest on disk
    enc_path = os.path.join(TEMP_SHARES_DIR, f"{share_id}.enc")
    assert os.path.exists(enc_path)
    with open(enc_path, "rb") as f:
        ciphertext = f.read()
    assert ciphertext != file_content
    assert file_content not in ciphertext

    # 3. Public metadata endpoint
    meta_res = await async_client.get(f"/temporary-shares/{share_id}")
    assert meta_res.status_code == 200
    meta = meta_res.json()
    assert meta["share_id"] == share_id
    assert meta["original_filename"] == "audit_report.pdf"
    assert meta["remaining_seconds"] > 580
    assert "password" not in meta
    assert "salt" not in meta

    # 4. Verify password
    verify_ok = await async_client.post(
        f"/temporary-shares/{share_id}/verify",
        json={"password": password}
    )
    assert verify_ok.status_code == 200
    assert verify_ok.json()["success"] is True

    verify_bad = await async_client.post(
        f"/temporary-shares/{share_id}/verify",
        json={"password": "WrongPassword!"}
    )
    assert verify_bad.status_code == 401

    # 5. Download with correct password
    dl_res = await async_client.post(
        f"/temporary-shares/{share_id}/download",
        data={"password": password}
    )
    assert dl_res.status_code == 200
    assert dl_res.content == file_content
    assert "application/pdf" in dl_res.headers.get("content-type", "")
    assert "audit_report.pdf" in dl_res.headers.get("content-disposition", "")

    # 6. Serve HTML recipient page
    html_res = await async_client.get(f"/share/{share_id}")
    assert html_res.status_code == 200
    assert "text/html" in html_res.headers.get("content-type", "")
    assert "audit_report.pdf" in html_res.text


@pytest.mark.asyncio
async def test_expired_temporary_share_denies_access(async_client):
    db = get_db()
    file_content = b"Expiring data"
    password = "Password999"

    files = {"file": ("data.txt", io.BytesIO(file_content), "text/plain")}
    data = {"password": password}

    res = await async_client.post("/temporary-shares", files=files, data=data)
    assert res.status_code == 200
    share_id = res.json()["share_id"]

    # Manually simulate expiration by setting expires_at to 1 minute ago
    past_time = datetime.now(timezone.utc) - timedelta(minutes=1)
    await db.temporary_shares.update_one(
        {"share_id": share_id},
        {"$set": {"expires_at": past_time}}
    )

    # Attempt metadata -> 410 Gone
    meta_res = await async_client.get(f"/temporary-shares/{share_id}")
    assert meta_res.status_code == 410

    # Attempt download -> 410 Gone
    dl_res = await async_client.post(
        f"/temporary-shares/{share_id}/download",
        data={"password": password}
    )
    assert dl_res.status_code == 410

    # Attempt HTML page -> shows Expired
    html_res = await async_client.get(f"/share/{share_id}")
    assert html_res.status_code == 410
    assert "Share Expired" in html_res.text


@pytest.mark.asyncio
async def test_manual_revocation(async_client):
    file_content = b"Revocable secrets"
    password = "Password888"

    files = {"file": ("confidential.txt", io.BytesIO(file_content), "text/plain")}
    data = {"password": password}

    res = await async_client.post("/temporary-shares", files=files, data=data)
    share_id = res.json()["share_id"]

    # Revoke
    rev_res = await async_client.delete(f"/temporary-shares/{share_id}")
    assert rev_res.status_code == 200

    # Subsequent access must be rejected
    meta_res = await async_client.get(f"/temporary-shares/{share_id}")
    assert meta_res.status_code == 410

    dl_res = await async_client.post(
        f"/temporary-shares/{share_id}/download",
        data={"password": password}
    )
    assert dl_res.status_code == 410


@pytest.mark.asyncio
async def test_rate_limiting_on_brute_force(async_client):
    file_content = b"Rate limit check"
    password = "TargetPassword123"

    files = {"file": ("check.txt", io.BytesIO(file_content), "text/plain")}
    data = {"password": password}

    res = await async_client.post("/temporary-shares", files=files, data=data)
    share_id = res.json()["share_id"]

    # Fail 5 times
    for _ in range(5):
        fail_res = await async_client.post(
            f"/temporary-shares/{share_id}/verify",
            json={"password": "IncorrectPassword"}
        )
        assert fail_res.status_code == 401

    # 6th attempt should trigger 429 Rate Limit
    rate_res = await async_client.post(
        f"/temporary-shares/{share_id}/verify",
        json={"password": "IncorrectPassword"}
    )
    assert rate_res.status_code == 429
