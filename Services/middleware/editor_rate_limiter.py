"""
PaperKit PDF Editor Rate Limiter
Tracks client daily edit operations using an isolated SQLite database.
Enforces 3 edit operations per client per calendar day.
"""
import os
import sqlite3
import datetime
from fastapi import Request, HTTPException, status, Response

DB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "storage")
DB_PATH = os.path.join(DB_DIR, "rate_limits.db")

DAILY_LIMIT = 3
COOKIE_NAME = "paperkit_client_id"

def init_db():
    os.makedirs(DB_DIR, exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS daily_limits (
                client_key TEXT NOT NULL,
                usage_date TEXT NOT NULL,
                count INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (client_key, usage_date)
            )
        """)
        conn.commit()

init_db()

def get_client_key(request: Request, response: Response = None) -> str:
    """Extract or generate client identifier based on IP and cookie token."""
    client_ip = request.client.host if request.client else "127.0.0.1"
    cookie_token = request.cookies.get(COOKIE_NAME)
    
    if not cookie_token:
        import uuid
        cookie_token = str(uuid.uuid4())
        if response:
            # Set cookie for 1 year
            response.set_cookie(
                key=COOKIE_NAME,
                value=cookie_token,
                max_age=31536000,
                httponly=True,
                samesite="lax"
            )
    return f"{client_ip}:{cookie_token}"

def get_today_date_str() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

def get_remaining_edits(client_key: str) -> tuple[int, int]:
    """Return (remaining_edits, max_limit) for current date."""
    today = get_today_date_str()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT count FROM daily_limits WHERE client_key = ? AND usage_date = ?",
                (client_key, today)
            )
            row = cursor.fetchone()
            used_count = row[0] if row else 0
            remaining = max(0, DAILY_LIMIT - used_count)
            return remaining, DAILY_LIMIT
    except Exception as e:
        print(f"[RateLimiter Error] Failed to read remaining edits: {e}")
        return DAILY_LIMIT, DAILY_LIMIT

def enforce_editor_rate_limit(request: Request, response: Response = None) -> tuple[str, int]:
    """
    Check if client is allowed to perform an edit.
    Increments count if allowed. Raises HTTP 429 if limit exceeded.
    Returns (client_key, remaining_edits_after_op).
    """
    client_key = get_client_key(request, response)
    today = get_today_date_str()
    
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT count FROM daily_limits WHERE client_key = ? AND usage_date = ?",
            (client_key, today)
        )
        row = cursor.fetchone()
        current_count = row[0] if row else 0
        
        if current_count >= DAILY_LIMIT:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Daily free limit reached (3/3). Resets at midnight."
            )
        
        new_count = current_count + 1
        cursor.execute("""
            INSERT INTO daily_limits (client_key, usage_date, count)
            VALUES (?, ?, ?)
            ON CONFLICT(client_key, usage_date) DO UPDATE SET count = ?
        """, (client_key, today, new_count, new_count))
        conn.commit()
        
        remaining = max(0, DAILY_LIMIT - new_count)
        return client_key, remaining
