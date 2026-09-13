"""MaskerV 10-Minute Temporary Encrypted File Sharing Router.

Enforces:
- Exact server-authoritative 10-minute expiration.
- AES-256-GCM encryption at rest with zero plaintext password storage.
- Brute-force rate limiting.
- Immediate manual revocation.
- Automatic cleanup of expired ciphertext files.
"""
import os
import re
import secrets
import html
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends, Request, Response, BackgroundTasks
from fastapi.responses import HTMLResponse, Response
from pydantic import BaseModel

from database import get_db
from config import get_settings
from middleware.auth import get_current_user
from services.crypto_service import (
    encrypt_temporary_file,
    decrypt_temporary_file,
    check_verifier_password,
)

settings = get_settings()
router = APIRouter()

TEMP_SHARES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "storage", "temp_shares")
os.makedirs(TEMP_SHARES_DIR, exist_ok=True)

MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024  # 50 MB max temporary file size
MAX_PASSWORD_ATTEMPTS = 5


def sanitize_filename(filename: str) -> str:
    """Sanitize uploaded filename to prevent directory traversal and header injection."""
    base = os.path.basename(filename).strip()
    clean = re.sub(r'[^a-zA-Z0-9._\-+ ]', '_', base)
    return clean[:120] if clean else "shared_file.bin"


async def purge_share_file(share_id: str):
    """Safely delete encrypted ciphertext file from disk."""
    enc_path = os.path.join(TEMP_SHARES_DIR, f"{share_id}.enc")
    try:
        if os.path.exists(enc_path):
            os.remove(enc_path)
    except Exception as e:
        print(f"[TempShare] Error purging encrypted file {enc_path}: {e}")


async def cleanup_expired_temporary_shares(db) -> int:
    """Auto-clean expired temporary shares from disk and MongoDB."""
    if db is None:
        return 0
    now = datetime.now(timezone.utc)
    cleaned = 0

    try:
        # Find active shares that have passed expires_at
        cursor = db.temporary_shares.find({
            "status": "active",
            "expires_at": {"$lte": now}
        })
        async for doc in cursor:
            share_id = doc.get("share_id")
            if share_id:
                await purge_share_file(share_id)
            await db.temporary_shares.update_one(
                {"_id": doc["_id"]},
                {"$set": {"status": "expired", "expired_at": now}}
            )
            cleaned += 1

        # Also purge any orphaned files in TEMP_SHARES_DIR older than 15 minutes
        if os.path.exists(TEMP_SHARES_DIR):
            cutoff_sec = 15 * 60
            for fname in os.listdir(TEMP_SHARES_DIR):
                if fname.endswith(".enc"):
                    fpath = os.path.join(TEMP_SHARES_DIR, fname)
                    if os.path.isfile(fpath):
                        if (datetime.now().timestamp() - os.path.getmtime(fpath)) > cutoff_sec:
                            try:
                                os.remove(fpath)
                                cleaned += 1
                            except Exception:
                                pass
    except Exception as e:
        print(f"[TempShare] Auto-cleanup error: {e}")

    return cleaned


@router.post("/temporary-shares")
async def create_temporary_share(
    request: Request,
    file: UploadFile = File(...),
    password: str = Form(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload and encrypt a file with server-authoritative 10-minute expiration."""
    if not password or len(password.strip()) < 4:
        raise HTTPException(status_code=400, detail="Share password must be at least 4 characters long.")

    file_bytes = await file.read()
    if len(file_bytes) == 0:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    if len(file_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail=f"File exceeds maximum allowed size of 50 MB.")

    share_id = f"pk_{secrets.token_urlsafe(12)}"
    safe_name = sanitize_filename(file.filename or "file")
    content_type = file.content_type or "application/octet-stream"

    # Encrypt file bytes at rest with unique salt & nonce
    enc_result = encrypt_temporary_file(file_bytes, password.strip(), share_id)

    # Store ciphertext
    enc_path = os.path.join(TEMP_SHARES_DIR, f"{share_id}.enc")
    with open(enc_path, "wb") as f:
        f.write(enc_result["ciphertext"])

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=10)

    db = get_db()
    share_doc = {
        "share_id": share_id,
        "original_filename": safe_name,
        "file_size": len(file_bytes),
        "content_type": content_type,
        "salt_hex": enc_result["salt_hex"],
        "nonce_hex": enc_result["nonce_hex"],
        "verifier_hash": enc_result["verifier_hash"],
        "created_at": now,
        "expires_at": expires_at,
        "status": "active",
        "download_count": 0,
        "failed_attempts": 0,
        "created_by": str(current_user.get("_id", "guest")),
    }

    if db is not None:
        await db.temporary_shares.insert_one(share_doc)

    # Generate access URL with production-ready Render backend URL
    production_url = (getattr(settings, "backend_url", None) or "https://paperkit-backend.onrender.com").rstrip("/")
    share_url = f"{production_url}/share/{share_id}"

    return {
        "success": True,
        "share_id": share_id,
        "share_url": share_url,
        "access_url": share_url,
        "original_filename": safe_name,
        "file_size": len(file_bytes),
        "content_type": content_type,
        "created_at": now.isoformat(),
        "expires_at": expires_at.isoformat(),
        "expires_in_seconds": 600,
        "message": "Temporary file encrypted. Valid for exactly 10 minutes.",
    }


@router.get("/temporary-shares/{share_id}")
async def get_temporary_share_info(share_id: str):
    """Retrieve public metadata for a temporary share. Verifies server-side 10-minute expiry."""
    db = get_db()
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable.")

    doc = await db.temporary_shares.find_one({"share_id": share_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Temporary share not found.")

    now = datetime.now(timezone.utc)
    expires_at = doc.get("expires_at")
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    # Strict server-side expiration check
    if now >= expires_at or doc.get("status") != "active":
        if doc.get("status") == "active":
            await db.temporary_shares.update_one(
                {"_id": doc["_id"]},
                {"$set": {"status": "expired", "expired_at": now}}
            )
            await purge_share_file(share_id)

        raise HTTPException(
            status_code=410,
            detail="This share has expired. Temporary shares are valid for 10 minutes only.",
        )

    remaining_seconds = max(0, int((expires_at - now).total_seconds()))

    return {
        "share_id": share_id,
        "original_filename": doc.get("original_filename"),
        "file_size": doc.get("file_size"),
        "content_type": doc.get("content_type"),
        "created_at": doc.get("created_at").isoformat() if hasattr(doc.get("created_at"), "isoformat") else str(doc.get("created_at")),
        "expires_at": expires_at.isoformat(),
        "remaining_seconds": remaining_seconds,
        "status": "active",
        "requires_password": True,
    }


class VerifyPasswordRequest(BaseModel):
    password: str


@router.post("/temporary-shares/{share_id}/verify")
async def verify_temporary_share_password(share_id: str, payload: VerifyPasswordRequest):
    """Verify decryption password before download with brute-force rate limiting."""
    db = get_db()
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable.")

    doc = await db.temporary_shares.find_one({"share_id": share_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Temporary share not found.")

    now = datetime.now(timezone.utc)
    expires_at = doc.get("expires_at")
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if now >= expires_at or doc.get("status") != "active":
        raise HTTPException(status_code=410, detail="This share has expired.")

    # Rate limiting protection
    if doc.get("failed_attempts", 0) >= MAX_PASSWORD_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail="Too many incorrect password attempts. Access temporarily locked.",
        )

    password = payload.password.strip()
    is_valid = check_verifier_password(
        password,
        bytes.fromhex(doc["salt_hex"]),
        doc["verifier_hash"]
    )

    if not is_valid:
        await db.temporary_shares.update_one(
            {"_id": doc["_id"]},
            {"$inc": {"failed_attempts": 1}}
        )
        remaining = MAX_PASSWORD_ATTEMPTS - (doc.get("failed_attempts", 0) + 1)
        raise HTTPException(
            status_code=401,
            detail=f"Invalid password. {max(0, remaining)} attempts remaining.",
        )

    # Reset failed attempts on success
    await db.temporary_shares.update_one(
        {"_id": doc["_id"]},
        {"$set": {"failed_attempts": 0}}
    )

    return {"success": True, "share_id": share_id, "message": "Password verified."}


@router.post("/temporary-shares/{share_id}/download")
async def download_temporary_share(
    share_id: str,
    password: str = Form(...),
):
    """Validate server expiry, verify credentials, decrypt in-memory and stream file to client."""
    db = get_db()
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable.")

    doc = await db.temporary_shares.find_one({"share_id": share_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Temporary share not found.")

    now = datetime.now(timezone.utc)
    expires_at = doc.get("expires_at")
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    # Strict server-side expiration validation
    if now >= expires_at or doc.get("status") != "active":
        await purge_share_file(share_id)
        raise HTTPException(
            status_code=410,
            detail="This share has expired. Temporary shares are valid for 10 minutes only.",
        )

    # Check rate limit
    if doc.get("failed_attempts", 0) >= MAX_PASSWORD_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail="Too many incorrect password attempts. Access temporarily locked.",
        )

    enc_path = os.path.join(TEMP_SHARES_DIR, f"{share_id}.enc")
    if not os.path.exists(enc_path):
        raise HTTPException(status_code=410, detail="Shared file no longer exists.")

    try:
        with open(enc_path, "rb") as f:
            ciphertext = f.read()

        decrypted_bytes = decrypt_temporary_file(
            ciphertext=ciphertext,
            password=password.strip(),
            salt_hex=doc["salt_hex"],
            nonce_hex=doc["nonce_hex"],
            share_id=share_id,
        )
    except ValueError:
        await db.temporary_shares.update_one(
            {"_id": doc["_id"]},
            {"$inc": {"failed_attempts": 1}}
        )
        raise HTTPException(status_code=401, detail="Invalid share password.")

    # Record successful download
    await db.temporary_shares.update_one(
        {"_id": doc["_id"]},
        {"$inc": {"download_count": 1}, "$set": {"failed_attempts": 0}}
    )

    safe_filename = doc.get("original_filename", "downloaded_file")
    content_type = doc.get("content_type", "application/octet-stream")

    return Response(
        content=decrypted_bytes,
        media_type=content_type,
        headers={
            "Content-Disposition": f'attachment; filename="{safe_filename}"',
            "Content-Length": str(len(decrypted_bytes)),
            "X-Filename": safe_filename,
            "Cache-Control": "no-store, no-cache, must-revalidate, private",
        },
    )


@router.delete("/temporary-shares/{share_id}")
async def revoke_temporary_share(share_id: str):
    """Manually revoke a temporary share before expiration."""
    db = get_db()
    if db is None:
        raise HTTPException(status_code=503, detail="Database unavailable.")

    doc = await db.temporary_shares.find_one({"share_id": share_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Temporary share not found.")

    await purge_share_file(share_id)
    await db.temporary_shares.update_one(
        {"_id": doc["_id"]},
        {"$set": {"status": "revoked", "revoked_at": datetime.now(timezone.utc)}}
    )

    return {"success": True, "message": "Temporary share revoked successfully."}


@router.get("/share/{share_id}", response_class=HTMLResponse)
async def serve_share_recipient_page(share_id: str):
    """Serve a responsive, branded, self-contained recipient HTML page.
    
    Permits any standard smartphone camera or external QR scanner to view and download
    the shared file without needing an app pre-installed.
    """
    db = get_db()
    if db is None:
        return HTMLResponse("<h3>Database service unavailable</h3>", status_code=503)

    doc = await db.temporary_shares.find_one({"share_id": share_id})
    if not doc:
        return HTMLResponse(
            _render_error_page("Share Not Found", "The requested temporary share does not exist or has been deleted."),
            status_code=404,
        )

    now = datetime.now(timezone.utc)
    expires_at = doc.get("expires_at")
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if now >= expires_at or doc.get("status") != "active":
        return HTMLResponse(
            _render_error_page(
                "Share Expired",
                "This temporary share has expired. Temporary shares are strictly valid for 10 minutes only.",
            ),
            status_code=410,
        )

    remaining_seconds = max(0, int((expires_at - now).total_seconds()))
    filename = html.escape(doc.get("original_filename", "Shared File"))
    file_size_mb = f"{(doc.get('file_size', 0) / (1024 * 1024)):.2f} MB" if doc.get('file_size', 0) > 1024*1024 else f"{(doc.get('file_size', 0) / 1024):.1f} KB"

    return HTMLResponse(
        _render_recipient_page(
            share_id=share_id,
            filename=filename,
            file_size_str=file_size_mb,
            remaining_seconds=remaining_seconds,
            expires_at_iso=expires_at.isoformat(),
        )
    )


def _render_error_page(title: str, message: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MaskerV Secure Share — {title}</title>
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 16px;
    }}
    .card {{
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 32px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    }}
    .icon {{ font-size: 48px; margin-bottom: 16px; }}
    h1 {{ font-size: 22px; margin: 0 0 12px; color: #f87171; }}
    p {{ font-size: 14px; color: #94a3b8; line-height: 1.5; margin: 0; }}
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">⌛</div>
    <h1>{title}</h1>
    <p>{message}</p>
  </div>
</body>
</html>"""


def _render_recipient_page(share_id: str, filename: str, file_size_str: str, remaining_seconds: int, expires_at_iso: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MaskerV Secure Share</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #090d16;
      color: #f8fafc;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 16px;
    }}
    .card {{
      background: #131b2e;
      border: 1px solid #1e293b;
      border-radius: 20px;
      padding: 32px;
      max-width: 460px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.6);
      text-align: center;
    }}
    .logo {{
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      color: #6366f1;
      margin-bottom: 20px;
      display: inline-block;
      background: rgba(99, 102, 241, 0.12);
      padding: 4px 12px;
      border-radius: 20px;
    }}
    .file-box {{
      background: #0f172a;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 16px;
      margin: 16px 0 24px;
      text-align: left;
      display: flex;
      align-items: center;
      gap: 14px;
    }}
    .file-icon {{
      width: 44px;
      height: 44px;
      border-radius: 10px;
      background: rgba(56, 189, 248, 0.12);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #38bdf8;
      font-size: 20px;
    }}
    .file-meta {{ overflow: hidden; }}
    .filename {{
      font-weight: 600;
      font-size: 15px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      color: #e2e8f0;
    }}
    .filesize {{ font-size: 12px; color: #64748b; margin-top: 4px; }}
    .timer-container {{
      background: rgba(239, 68, 68, 0.08);
      border: 1px solid rgba(239, 68, 68, 0.2);
      padding: 10px;
      border-radius: 10px;
      margin-bottom: 20px;
      font-size: 13px;
      color: #f87171;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }}
    .timer {{ font-weight: 700; font-family: monospace; font-size: 15px; }}
    input[type="password"] {{
      width: 100%;
      background: #0b1120;
      border: 1px solid #334155;
      color: #f8fafc;
      padding: 14px 16px;
      border-radius: 10px;
      font-size: 15px;
      margin-bottom: 16px;
      outline: none;
      transition: border-color 0.2s;
    }}
    input[type="password"]:focus {{ border-color: #6366f1; }}
    button {{
      width: 100%;
      background: #4f46e5;
      color: white;
      border: none;
      padding: 14px;
      border-radius: 10px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: background 0.2s;
    }}
    button:hover {{ background: #4338ca; }}
    button:disabled {{ background: #334155; cursor: not-allowed; }}
    .status-msg {{
      margin-top: 14px;
      font-size: 13px;
      min-height: 18px;
    }}
    .error-msg {{ color: #f87171; }}
    .success-msg {{ color: #4ade80; }}
  </style>
</head>
<body>
  <div class="card" id="mainCard">
    <div class="logo">MaskerV 10-Min Secure Share</div>
    
    <div class="file-box">
      <div class="file-icon">📄</div>
      <div class="file-meta">
        <div class="filename" title="{filename}">{filename}</div>
        <div class="filesize">{file_size_str} • AES-256 Encrypted</div>
      </div>
    </div>

    <div class="timer-container">
      <span>Expires In:</span>
      <span class="timer" id="countdownTimer">--:--</span>
    </div>

    <form id="unlockForm" onsubmit="handleDownload(event)">
      <input type="password" id="passwordInput" placeholder="Enter share password" required autofocus autocomplete="off" />
      <button type="submit" id="submitBtn">
        <span>Unlock & Download File</span>
      </button>
    </form>

    <div class="status-msg" id="statusMsg"></div>
  </div>

  <script>
    let remainingSeconds = {remaining_seconds};
    const countdownEl = document.getElementById('countdownTimer');
    const submitBtn = document.getElementById('submitBtn');
    const passwordInput = document.getElementById('passwordInput');
    const statusMsg = document.getElementById('statusMsg');

    function updateTimer() {{
      if (remainingSeconds <= 0) {{
        countdownEl.innerText = "EXPIRED";
        submitBtn.disabled = true;
        passwordInput.disabled = true;
        statusMsg.className = "status-msg error-msg";
        statusMsg.innerText = "This share has expired. Temporary shares are valid for 10 minutes only.";
        return;
      }}
      const mins = Math.floor(remainingSeconds / 60);
      const secs = remainingSeconds % 60;
      countdownEl.innerText = `${{mins.toString().padStart(2, '0')}}:${{secs.toString().padStart(2, '0')}}`;
      remainingSeconds--;
      setTimeout(updateTimer, 1000);
    }}
    updateTimer();

    async function handleDownload(e) {{
      e.preventDefault();
      const password = passwordInput.value;
      if (!password) return;

      submitBtn.disabled = true;
      submitBtn.innerText = "Verifying & Decrypting...";
      statusMsg.innerText = "";
      statusMsg.className = "status-msg";

      try {{
        const formData = new FormData();
        formData.append('password', password);

        const res = await fetch('/temporary-shares/{share_id}/download', {{
          method: 'POST',
          body: formData
        }});

        if (res.status === 410) {{
          statusMsg.className = "status-msg error-msg";
          statusMsg.innerText = "This share has expired.";
          submitBtn.disabled = true;
          return;
        }}

        if (!res.ok) {{
          const data = await res.json().catch(() => ({{}}));
          statusMsg.className = "status-msg error-msg";
          statusMsg.innerText = data.detail || "Incorrect password or authorization error.";
          submitBtn.disabled = false;
          submitBtn.innerText = "Unlock & Download File";
          return;
        }}

        const blob = await res.blob();
        const disposition = res.headers.get('Content-Disposition');
        let filename = "{filename}";
        if (disposition && disposition.indexOf('filename=') !== -1) {{
          const matches = /filename[^;=\\n]*=((['"]).*?\\2|[^;\\n]*)/.exec(disposition);
          if (matches != null && matches[1]) {{
            filename = matches[1].replace(/['"]/g, '');
          }}
        }}

        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        a.remove();

        statusMsg.className = "status-msg success-msg";
        statusMsg.innerText = "File decrypted and downloaded successfully!";
        submitBtn.disabled = false;
        submitBtn.innerText = "Downloaded ✓ (Click to re-download)";
      }} catch (err) {{
        statusMsg.className = "status-msg error-msg";
        statusMsg.innerText = "Download error: " + err.message;
        submitBtn.disabled = false;
        submitBtn.innerText = "Unlock & Download File";
      }}
    }}
  </script>
</body>
</html>"""
