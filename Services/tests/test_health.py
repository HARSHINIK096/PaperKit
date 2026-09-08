"""Health, Root and Static File Endpoints Test Suite"""
import pytest


@pytest.mark.asyncio
async def test_root_endpoint(client):
    """GET / returns active service metadata and API information."""
    resp = await client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "online"
    assert data["service"] == "PaperKit API"
    assert "version" in data
    assert "health" in data
    assert "docs" in data


@pytest.mark.asyncio
async def test_health_endpoint(client):
    """GET /health returns 200 OK status."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["service"] == "PaperKit API"


@pytest.mark.asyncio
async def test_favicon_endpoint(client):
    """GET /favicon.ico returns 204 No Content."""
    resp = await client.get("/favicon.ico")
    assert resp.status_code == 204


@pytest.mark.asyncio
async def test_openapi_docs(client):
    """GET /docs returns OpenAPI HTML."""
    resp = await client.get("/docs")
    assert resp.status_code == 200
    assert "swagger" in resp.text.lower() or "openapi" in resp.text.lower()
