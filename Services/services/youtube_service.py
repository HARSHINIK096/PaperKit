"""
PaperKit YouTube Extraction Service.
Production-grade extraction architecture using yt-dlp PO-Token provider (bgutil:http),
bounded timeouts, bounded retries, structured application errors, and strict security validation.
"""
import os
import re
import sys
import uuid
import time
import shutil
import asyncio
import logging
import subprocess
from enum import Enum
from typing import Optional, Tuple, Dict, Any

import yt_dlp
import yt_dlp.version

logger = logging.getLogger("youtube_service")
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# Structured Error Model
# ---------------------------------------------------------------------------

class YouTubeErrorCode(str, Enum):
    YOUTUBE_AUTH_REQUIRED = "YOUTUBE_AUTH_REQUIRED"
    YOUTUBE_BOT_PROTECTION = "YOUTUBE_BOT_PROTECTION"
    YOUTUBE_FORMAT_UNAVAILABLE = "YOUTUBE_FORMAT_UNAVAILABLE"
    YOUTUBE_VIDEO_UNAVAILABLE = "YOUTUBE_VIDEO_UNAVAILABLE"
    YOUTUBE_PRIVATE_VIDEO = "YOUTUBE_PRIVATE_VIDEO"
    YOUTUBE_REGION_RESTRICTED = "YOUTUBE_REGION_RESTRICTED"
    YOUTUBE_URL_INVALID = "YOUTUBE_URL_INVALID"
    YOUTUBE_EXTRACTION_TIMEOUT = "YOUTUBE_EXTRACTION_TIMEOUT"
    YOUTUBE_NETWORK_ERROR = "YOUTUBE_NETWORK_ERROR"
    YOUTUBE_UNKNOWN_ERROR = "YOUTUBE_UNKNOWN_ERROR"


ERROR_STATUS_MAP: Dict[YouTubeErrorCode, int] = {
    YouTubeErrorCode.YOUTUBE_AUTH_REQUIRED: 401,
    YouTubeErrorCode.YOUTUBE_BOT_PROTECTION: 403,
    YouTubeErrorCode.YOUTUBE_FORMAT_UNAVAILABLE: 422,
    YouTubeErrorCode.YOUTUBE_VIDEO_UNAVAILABLE: 404,
    YouTubeErrorCode.YOUTUBE_PRIVATE_VIDEO: 403,
    YouTubeErrorCode.YOUTUBE_REGION_RESTRICTED: 451,
    YouTubeErrorCode.YOUTUBE_URL_INVALID: 400,
    YouTubeErrorCode.YOUTUBE_EXTRACTION_TIMEOUT: 504,
    YouTubeErrorCode.YOUTUBE_NETWORK_ERROR: 502,
    YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR: 500,
}

USER_SAFE_ERROR_MESSAGES: Dict[YouTubeErrorCode, str] = {
    YouTubeErrorCode.YOUTUBE_AUTH_REQUIRED: "This YouTube video requires account authentication or is members-only.",
    YouTubeErrorCode.YOUTUBE_BOT_PROTECTION: "YouTube flagged this request with bot protection. Please try again in a few moments.",
    YouTubeErrorCode.YOUTUBE_FORMAT_UNAVAILABLE: "Requested video format or quality is not available for this video.",
    YouTubeErrorCode.YOUTUBE_VIDEO_UNAVAILABLE: "The requested YouTube video does not exist or has been removed.",
    YouTubeErrorCode.YOUTUBE_PRIVATE_VIDEO: "This YouTube video is private and cannot be accessed.",
    YouTubeErrorCode.YOUTUBE_REGION_RESTRICTED: "This YouTube video is not available in the server's geographic region.",
    YouTubeErrorCode.YOUTUBE_URL_INVALID: "Please provide a valid YouTube video URL.",
    YouTubeErrorCode.YOUTUBE_EXTRACTION_TIMEOUT: "YouTube extraction timed out. The video took too long to process.",
    YouTubeErrorCode.YOUTUBE_NETWORK_ERROR: "Network error communicating with YouTube servers. Please try again.",
    YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR: "An unexpected error occurred during YouTube extraction.",
}


class YouTubeExtractionError(Exception):
    """Structured application error for YouTube extraction failures."""
    def __init__(self, code: YouTubeErrorCode, detail: Optional[str] = None):
        self.code = code
        self.status_code = ERROR_STATUS_MAP.get(code, 500)
        self.message = USER_SAFE_ERROR_MESSAGES.get(code, "YouTube extraction failed.")
        self.detail = detail or self.message
        super().__init__(self.message)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "error_code": self.code.value,
            "message": self.message,
            "detail": self.detail,
        }


# ---------------------------------------------------------------------------
# Strict URL Validation
# ---------------------------------------------------------------------------

YOUTUBE_URL_REGEX = re.compile(
    r"^(https?://)?"
    r"(www\.|m\.|music\.)?"
    r"(youtube\.com/(watch\?(?:.*&)?v=|embed/|v/|shorts/)|youtu\.be/)"
    r"(?P<video_id>[a-zA-Z0-9_-]{11})"
    r"(?=[?&#\s]|$)",
    re.IGNORECASE,
)

def validate_and_normalize_youtube_url(url: str) -> Tuple[str, str]:
    """
    Validates a user-supplied YouTube URL and extracts the canonical video ID.
    Returns (canonical_url, video_id).
    Raises YouTubeExtractionError(YOUTUBE_URL_INVALID) if the URL is invalid.
    """
    if not url or not isinstance(url, str):
        raise YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_URL_INVALID, "URL cannot be empty.")

    clean_url = url.strip()

    # Reject dangerous schemes / command injection characters
    if any(char in clean_url for char in [";", "|", "`", "$", "\n", "\r", "<", ">"]):
        raise YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_URL_INVALID, "Invalid characters in URL.")

    # Reject non-http protocols (e.g. file://, ftp://, javascript:)
    if ":" in clean_url and not clean_url.startswith(("http://", "https://")):
        raise YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_URL_INVALID, "Only HTTP/HTTPS URLs are allowed.")

    match = YOUTUBE_URL_REGEX.match(clean_url)
    if not match:
        raise YouTubeExtractionError(
            YouTubeErrorCode.YOUTUBE_URL_INVALID,
            "The URL provided is not a supported YouTube video link."
        )

    video_id = match.group("video_id")
    canonical_url = f"https://www.youtube.com/watch?v={video_id}"
    return canonical_url, video_id


# ---------------------------------------------------------------------------
# Error Classifier
# ---------------------------------------------------------------------------

def classify_yt_dlp_error(error: Exception) -> YouTubeExtractionError:
    """
    Parses yt-dlp exceptions and maps them to structured application errors
    without exposing internal tokens, cookies, paths, or secrets.
    """
    err_str = str(error).lower()

    if "sign in to confirm you’re not a bot" in err_str or "sign in to confirm you're not a bot" in err_str or ("bot" in err_str and "confirm" in err_str):
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_BOT_PROTECTION)

    if "private video" in err_str or "this video is private" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_PRIVATE_VIDEO)

    if "members-only" in err_str or "members only" in err_str or "sign in if you've been granted access" in err_str or "login required" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_AUTH_REQUIRED)

    if "video unavailable" in err_str or "video is unavailable" in err_str or "this video is unavailable" in err_str or "does not exist" in err_str or "has been removed" in err_str or "not a valid video id" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_VIDEO_UNAVAILABLE)


    if "not available in your country" in err_str or "made this video available in your country" in err_str or "geographic" in err_str or "geoblocked" in err_str or "blocked in your country" in err_str or "not available in your region" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_REGION_RESTRICTED)

    if "requested format is not available" in err_str or "no video formats found" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_FORMAT_UNAVAILABLE)

    if "timed out" in err_str or "timeout" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_EXTRACTION_TIMEOUT)

    if "unable to download webpage" in err_str or "connection reset" in err_str or "connection refused" in err_str or "network" in err_str:
        return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_NETWORK_ERROR)

    return YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR, "YouTube extraction failed.")




# ---------------------------------------------------------------------------
# POT Provider Process Management & Health
# ---------------------------------------------------------------------------

_pot_server_process: Optional[subprocess.Popen] = None
DEFAULT_POT_URL = "http://127.0.0.1:4416"

def get_pot_provider_url() -> str:
    """Returns the configured PO-token provider URL."""
    return os.getenv("POT_PROVIDER_URL") or os.getenv("YTDL_POT_URL") or DEFAULT_POT_URL

def get_node_version() -> Optional[str]:
    """Returns the version of Node.js available in PATH if present."""
    node_bin = shutil.which("node")
    if not node_bin:
        # Check local bin directory as fallback
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        bin_node = os.path.join(base_dir, "bin", "node")
        if os.path.isfile(bin_node):
            node_bin = bin_node
    if node_bin:
        try:
            res = subprocess.run([node_bin, "-v"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                return res.stdout.strip()
        except Exception:
            pass
    return None

async def check_pot_provider_health(url: Optional[str] = None) -> bool:
    """Pings the PO-token provider HTTP ping endpoint."""
    import httpx
    target_url = url or get_pot_provider_url()
    ping_url = f"{target_url.rstrip('/')}/ping"
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(ping_url)
            if resp.status_code == 200:
                data = resp.json()
                return data.get("status") == "ok"
    except Exception:
        return False
    return False

async def check_pot_provider_operational(url: Optional[str] = None) -> bool:
    """
    Performs a real readiness check by requesting a PO token for a known video ID
    to verify that BotGuard/WebPoMinter token minting is functional.
    """
    import httpx
    target_url = url or get_pot_provider_url()
    pot_url = f"{target_url.rstrip('/')}/get_pot"
    payload = {
        "bypass_cache": True,
        "content_binding": "_Wv9oLUe740",
        "innertube_context": {}
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(pot_url, json=payload)
            if resp.status_code == 200:
                data = resp.json()
                return bool(data.get("poToken"))
    except Exception:
        return False
    return False

def start_local_pot_server() -> bool:
    """Starts the local Node.js POT provider server if Node.js is available."""
    global _pot_server_process
    if _pot_server_process and _pot_server_process.poll() is None:
        return True

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pot_server_dir = os.path.join(base_dir, "pot_server")
    server_js = os.path.join(pot_server_dir, "server.js")

    if not os.path.isfile(server_js):
        logger.warning("POT server script not found at %s", server_js)
        return False

    node_bin = shutil.which("node")
    if not node_bin:
        bin_node = os.path.join(base_dir, "bin", "node")
        if os.path.isfile(bin_node):
            node_bin = bin_node

    if not node_bin:
        logger.warning("Node.js binary not found in PATH or bin/ for local POT server.")
        return False

    try:
        env = {**os.environ, "POT_PORT": "4416", "POT_HOST": "127.0.0.1"}
        # Prepend bin directory to PATH for child process
        bin_dir = os.path.join(base_dir, "bin")
        if os.path.exists(bin_dir):
            env["PATH"] = bin_dir + os.pathsep + env.get("PATH", "")

        _pot_server_process = subprocess.Popen(
            [node_bin, "server.js"],
            cwd=pot_server_dir,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=env,
        )
        logger.info("Started local POT provider server (PID: %d)", _pot_server_process.pid)

        # Wait up to 3 seconds for readiness
        import urllib.request
        for _ in range(15):
            time.sleep(0.2)
            try:
                with urllib.request.urlopen("http://127.0.0.1:4416/ping", timeout=1) as resp:
                    if resp.status == 200:
                        logger.info("Local POT provider server ping succeeded on port 4416.")
                        return True
            except Exception:
                pass

        return True
    except Exception as e:
        logger.error("Failed to start local POT server: %s", e)
        return False

def stop_local_pot_server():
    """Stops the local POT server process."""
    global _pot_server_process
    if _pot_server_process:
        try:
            _pot_server_process.terminate()
            _pot_server_process.wait(timeout=3)
        except Exception:
            _pot_server_process.kill()
        finally:
            _pot_server_process = None
            logger.info("Stopped local POT provider server.")


# ---------------------------------------------------------------------------
# Core Extraction Pipeline
# ---------------------------------------------------------------------------

class YouTubeService:
    def __init__(self, download_dir: str):
        self.download_dir = download_dir
        os.makedirs(self.download_dir, exist_ok=True)
        self.max_extraction_seconds = int(os.getenv("YOUTUBE_TIMEOUT_SECONDS", "45"))
        self.max_retries = 1


    def find_ffmpeg_location(self) -> Optional[str]:
        """Finds FFmpeg executable path."""
        from spotify_downloader import find_ffmpeg_path
        return find_ffmpeg_path()

    def build_ydl_options(self, output_template: str, pot_url: Optional[str] = None) -> Dict[str, Any]:
        """
        Builds production-grade yt-dlp options using official PO-token provider and Node JS runtime.
        """
        ffmpeg_bin = self.find_ffmpeg_location()
        active_pot_url = pot_url or get_pot_provider_url()

        ydl_opts: Dict[str, Any] = {
            "outtmpl": output_template,
            "format": "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
            "merge_output_format": "mp4",
            "quiet": True,
            "no_warnings": True,
            "ignoreerrors": False,
            "socket_timeout": 15,
            "js_runtimes": {"node": {}},
            "extractor_args": {
                "youtubepot-bgutilhttp": {
                    "base_url": [active_pot_url],
                },
                "youtube": {
                    "player_client": ["mweb", "web_safari", "web"],
                },
            },
        }

        if ffmpeg_bin:
            ydl_opts["ffmpeg_location"] = os.path.dirname(ffmpeg_bin) if os.path.isfile(ffmpeg_bin) else ffmpeg_bin

        proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")
        if proxy_url:
            ydl_opts["proxy"] = proxy_url

        return ydl_opts

    def _sync_extract(self, canonical_url: str, output_template: str, pot_url: str):
        """Synchronous yt-dlp execution within bounded thread."""
        ydl_opts = self.build_ydl_options(output_template, pot_url)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([canonical_url])

    async def download_video(self, url: str) -> Tuple[str, str]:
        """
        Executes bounded, secure YouTube video extraction.
        Returns (downloaded_file_path, display_filename).
        Raises YouTubeExtractionError on any failure.
        """
        canonical_url, video_id = validate_and_normalize_youtube_url(url)
        job_id = str(uuid.uuid4())
        output_template = os.path.join(self.download_dir, f"{job_id}_%(title)s.%(ext)s")
        pot_url = get_pot_provider_url()

        logger.info("YouTube extraction started for video_id=%s (job_id=%s)", video_id, job_id)
        start_time = time.time()

        last_err: Optional[YouTubeExtractionError] = None
        for attempt in range(self.max_retries + 1):
            try:
                await asyncio.wait_for(
                    asyncio.to_thread(self._sync_extract, canonical_url, output_template, pot_url),
                    timeout=self.max_extraction_seconds
                )
                # Successful extraction, find the file
                downloaded_file = None
                for fname in os.listdir(self.download_dir):
                    if fname.startswith(f"{job_id}_") and os.path.isfile(os.path.join(self.download_dir, fname)):
                        downloaded_file = os.path.join(self.download_dir, fname)
                        break

                if not downloaded_file or not os.path.exists(downloaded_file) or os.path.getsize(downloaded_file) < 1024:
                    raise YouTubeExtractionError(
                        YouTubeErrorCode.YOUTUBE_FORMAT_UNAVAILABLE,
                        "Video downloaded file could not be verified."
                    )

                duration = time.time() - start_time
                display_name = os.path.basename(downloaded_file).replace(f"{job_id}_", "")
                logger.info("YouTube extraction succeeded for video_id=%s in %.2fs (file=%s)", video_id, duration, display_name)
                return downloaded_file, display_name

            except asyncio.TimeoutError:
                logger.warning("YouTube extraction timeout for video_id=%s after %ds", video_id, self.max_extraction_seconds)
                self._cleanup_job_files(job_id)
                raise YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_EXTRACTION_TIMEOUT)

            except YouTubeExtractionError as yte:
                logger.warning("YouTube extraction application error [%s] for video_id=%s", yte.code.value, video_id)
                self._cleanup_job_files(job_id)
                raise yte

            except Exception as exc:
                classified = classify_yt_dlp_error(exc)
                logger.warning("YouTube extraction error [%s] for video_id=%s on attempt %d: %s", classified.code.value, video_id, attempt + 1, exc)
                last_err = classified

                # Do NOT retry non-transient errors (bot protection, auth, unavailable, format)
                if classified.code not in [YouTubeErrorCode.YOUTUBE_NETWORK_ERROR]:
                    self._cleanup_job_files(job_id)
                    raise classified

                if attempt < self.max_retries:
                    await asyncio.sleep(1.0)
                    continue

        self._cleanup_job_files(job_id)
        raise last_err or YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR)

    def _cleanup_job_files(self, job_id: str):
        """Cleans up partial or failed download artifacts for a specific job."""
        try:
            for fname in os.listdir(self.download_dir):
                if fname.startswith(f"{job_id}_"):
                    fpath = os.path.join(self.download_dir, fname)
                    if os.path.isfile(fpath):
                        os.remove(fpath)
        except Exception as e:
            logger.debug("Error during job file cleanup: %s", e)
