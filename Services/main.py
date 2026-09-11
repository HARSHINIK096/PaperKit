"""MASKERV FastAPI application entry point — Open-Source PDF & Document Suite"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os
import sys

# Ensure local bin directory (containing ffmpeg/ffprobe) is on PATH
bin_dir = os.path.join(os.path.dirname(__file__), "bin")
if os.path.exists(bin_dir):
    os.environ["PATH"] = bin_dir + os.pathsep + os.environ.get("PATH", "")

import asyncio
from services.storage import cleanup_expired_guest_files
from database import get_db, close_client
from config import get_settings
from routers.auth import router as auth_router
from routers.files import router as files_router
from routers.tools import router as tools_router
from routers.ai import router as ai_router
from routers.jobs import router as jobs_router
from services import job_service

settings = get_settings()

# Ensure __init__.py files exist
for pkg in ["routers", "services", "models", "middleware"]:
    init = os.path.join(os.path.dirname(__file__), pkg, "__init__.py")
    if not os.path.exists(init):
        open(init, "w").close()


async def _guest_cleanup_loop():
    while True:
        try:
            db = get_db()
            cleaned = await cleanup_expired_guest_files(db, max_age_minutes=15)
            if cleaned > 0:
                print(f"[Storage] Auto-purged {cleaned} ephemeral/session storage files & chunks.")
            await asyncio.sleep(180)  # Run every 3 minutes
        except asyncio.CancelledError:
            break
        except Exception as e:
            print(f"[Storage] Auto-cleanup error: {e}")
            await asyncio.sleep(180)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup — launch background job worker & guest cleanup task
    await job_service.start_worker()
    cleanup_task = asyncio.create_task(_guest_cleanup_loop())
    yield
    # Shutdown
    cleanup_task.cancel()
    await job_service.stop_worker()
    await close_client()


app = FastAPI(
    title="MASKERV API",
    description="Open-Source PDF & Document Suite — backend API",
    version="2.1.0",
    lifespan=lifespan,
)

origins = [
    settings.frontend_url,
    "https://paperkit-web.onrender.com",
    "http://localhost:5173",
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:3000",
    "http://localhost",
    "https://localhost",
    "capacitor://localhost",
    "ionic://localhost",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:[0-9]+)?|capacitor://.*|ionic://.*|https://.*\.onrender\.com",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition", "Content-Length", "X-Filename"],
)

# HTTP Request & Response Logging Middleware
import time
from fastapi import Request

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    method = request.method
    path = request.url.path
    client_ip = request.client.host if request.client else "127.0.0.1"
    
    try:
        response = await call_next(request)
        response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
        duration_ms = (time.time() - start_time) * 1000
        print(f"[API LOG] {method} {path} => Status: {response.status_code} ({duration_ms:.2f}ms) | Client: {client_ip}")
        return response
    except Exception as exc:
        duration_ms = (time.time() - start_time) * 1000
        print(f"[API LOG ERROR] {method} {path} => FAILED: {exc} ({duration_ms:.2f}ms) | Client: {client_ip}")
        raise exc


from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Safely serialize validation errors without crashing on binary bytes."""
    cleaned_errors = []
    for err in exc.errors():
        err_dict = dict(err)
        inp = err_dict.get("input")
        if isinstance(inp, bytes):
            err_dict["input"] = f"<binary data: {len(inp)} bytes>"
        elif isinstance(inp, (list, tuple)):
            err_dict["input"] = [f"<binary data: {len(x)} bytes>" if isinstance(x, bytes) else x for x in inp]
        elif isinstance(inp, dict):
            err_dict["input"] = {k: f"<binary data: {len(v)} bytes>" if isinstance(v, bytes) else v for k, v in inp.items()}
        cleaned_errors.append(err_dict)
    return JSONResponse(status_code=422, content={"detail": cleaned_errors})


# Custom StaticFiles wrapper with explicit OpenXML/PDF MIME types & Content-Disposition
class CustomStaticFiles(StaticFiles):
    async def get_response(self, path: str, scope):
        response = await super().get_response(path, scope)
        filename = os.path.basename(path)
        ext = filename.rsplit('.', 1)[-1].lower() if '.' in filename else ''
        mime_types = {
            'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'doc': 'application/msword',
            'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'xls': 'application/vnd.ms-excel',
            'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'ppt': 'application/vnd.ms-powerpoint',
            'pdf': 'application/pdf',
            'txt': 'text/plain; charset=utf-8',
            'html': 'text/html; charset=utf-8',
            'md': 'text/markdown; charset=utf-8',
        }
        if ext in mime_types:
            response.headers['content-type'] = mime_types[ext]
        response.headers['content-disposition'] = f'attachment; filename="{filename}"'
        response.headers['access-control-expose-headers'] = 'Content-Disposition, Content-Type'
        return response

storage_dir = os.path.join(os.path.dirname(__file__), "storage")
os.makedirs(storage_dir, exist_ok=True)
app.mount("/storage", CustomStaticFiles(directory=storage_dir), name="storage")

from routers.media import router as media_router
from routers.editor import router as editor_router

# Routers
app.include_router(auth_router)
app.include_router(auth_router, prefix="/api")
app.include_router(files_router)
app.include_router(files_router, prefix="/api")
app.include_router(tools_router)
app.include_router(tools_router, prefix="/api")
app.include_router(ai_router)
app.include_router(ai_router, prefix="/api")
app.include_router(jobs_router)
app.include_router(jobs_router, prefix="/api")
app.include_router(media_router, prefix="/media", tags=["media"])
app.include_router(media_router, prefix="/api/media", tags=["media"])
app.include_router(editor_router, prefix="/editor", tags=["editor"])
app.include_router(editor_router, prefix="/api/editor", tags=["editor"])


from fastapi.responses import Response

@app.api_route("/", methods=["GET", "HEAD"])
async def root():
    return {
        "status": "online",
        "service": "MASKERV API",
        "version": "2.1.0",
        "docs": "/docs",
        "health": "/health",
        "environment": settings.environment if hasattr(settings, 'environment') else "production"
    }

@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return Response(status_code=204)

@app.api_route("/health", methods=["GET", "HEAD"])
async def health():
    return {"status": "ok", "service": "MASKERV API", "version": "2.1.0"}
