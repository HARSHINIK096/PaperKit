"""Async Background Job Processing Test Suite"""
import pytest
from services.job_service import JobStatus


@pytest.mark.asyncio
async def test_create_and_get_job(client, seeded_user, auth_headers):
    """POST /jobs creates job, GET /jobs/{id} fetches current state."""
    payload = {
        "operation": "compress",
        "inputAssets": ["storage/test_doc.pdf"],
        "parameters": {"level": "extreme"},
    }
    # 1. Create
    resp = await client.post("/jobs", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    job = resp.json()
    assert "jobId" in job
    assert job["status"] in [JobStatus.QUEUED, JobStatus.PROCESSING, JobStatus.VALIDATING]
    job_id = job["jobId"]

    # 2. Get
    resp_get = await client.get(f"/jobs/{job_id}", headers=auth_headers)
    assert resp_get.status_code == 200
    assert resp_get.json()["jobId"] == job_id


@pytest.mark.asyncio
async def test_list_user_jobs(client, seeded_user, auth_headers):
    """GET /jobs lists jobs for authenticated user."""
    resp = await client.get("/jobs", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert isinstance(data["items"], list)


@pytest.mark.asyncio
async def test_cancel_job(client, seeded_user, auth_headers):
    """DELETE /jobs/{id} cancels pending job."""
    payload = {
        "operation": "ocr",
        "inputAssets": ["storage/test_doc.pdf"],
        "parameters": {},
    }
    resp = await client.post("/jobs", json=payload, headers=auth_headers)
    assert resp.status_code == 200
    job_id = resp.json()["jobId"]

    resp_cancel = await client.delete(f"/jobs/{job_id}", headers=auth_headers)
    assert resp_cancel.status_code in [200, 400]
