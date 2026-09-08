"""Authentication and User Profile Test Suite"""
import pytest
from middleware.auth import hash_password, verify_password, create_access_token, decode_token


def test_password_hashing():
    """Verify bcrypt password hashing and verification."""
    password = "SuperSecretPassword123!"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("WrongPassword!", hashed) is False


def test_jwt_token_generation_and_decoding():
    """Verify JWT token creation and decoding."""
    payload = {"sub": "64b1f2e3d4c5b6a7f8e9d0c1", "role": "user"}
    token = create_access_token(payload)
    assert isinstance(token, str)
    decoded = decode_token(token)
    assert decoded["sub"] == payload["sub"]
    assert decoded["role"] == "user"
    assert "exp" in decoded


@pytest.mark.asyncio
async def test_register_success(client):
    """POST /auth/register creates a new user account."""
    resp = await client.post(
        "/auth/register",
        json={"name": "Alice Tester", "email": "alice@paperkit.dev", "password": "SecurePassword123!"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "user_id" in data
    assert data["message"] == "Account created successfully"


@pytest.mark.asyncio
async def test_register_missing_fields(client):
    """POST /auth/register fails if required fields are missing."""
    resp = await client.post("/auth/register", json={"email": "alice@paperkit.dev"})
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_register_short_password(client):
    """POST /auth/register rejects passwords under 8 chars."""
    resp = await client.post(
        "/auth/register",
        json={"name": "Short", "email": "short@paperkit.dev", "password": "123"},
    )
    assert resp.status_code == 400
    assert "8 characters" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_register_duplicate_email(client, seeded_user):
    """POST /auth/register rejects already registered email."""
    resp = await client.post(
        "/auth/register",
        json={
            "name": "Duplicate User",
            "email": seeded_user["email"],
            "password": "Password123!",
        },
    )
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client, seeded_user):
    """POST /auth/login returns JWT bearer token on valid credentials."""
    resp = await client.post(
        "/auth/login",
        data={"username": seeded_user["email"], "password": "TestPassword123!"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_invalid_password(client, seeded_user):
    """POST /auth/login returns 401 on incorrect password."""
    resp = await client.post(
        "/auth/login",
        data={"username": seeded_user["email"], "password": "WrongPassword999!"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_user(client):
    """POST /auth/login returns 401 on non-existent account."""
    resp = await client.post(
        "/auth/login",
        data={"username": "nonexistent@paperkit.dev", "password": "AnyPassword123!"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_current_user_profile(client, seeded_user, auth_headers):
    """GET /auth/me returns authenticated user's profile."""
    resp = await client.get("/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == seeded_user["email"]
    assert data["name"] == seeded_user["name"]


@pytest.mark.asyncio
async def test_update_user_profile(client, seeded_user, auth_headers):
    """PUT /auth/me updates user display name and preferences."""
    resp = await client.put(
        "/auth/me",
        headers=auth_headers,
        json={"name": "Updated Name", "preferences": {"dark_mode": False}},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Updated Name"


@pytest.mark.asyncio
async def test_delete_user_account(client, seeded_user, auth_headers):
    """DELETE /auth/delete-account removes user and related data."""
    resp = await client.delete("/auth/delete-account", headers=auth_headers)
    assert resp.status_code == 200
    assert "deleted successfully" in resp.json()["message"]
