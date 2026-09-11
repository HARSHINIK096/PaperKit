import os
import sys
import uuid
import subprocess
import yt_dlp
from fastapi import APIRouter, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from pydantic import BaseModel

router = APIRouter()


class DownloadRequest(BaseModel):
    url: str

# Use the scratch folder or temp dir to store downloads temporarily
DOWNLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scratch", "downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

def cleanup_file(filepath: str):
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
    except Exception as e:
        print(f"Error cleaning up file {filepath}: {e}")

import asyncio

from spotify_downloader import get_or_create_cookie_file, format_netscape_cookies

from services.youtube_service import (
    YouTubeService,
    YouTubeExtractionError,
    YouTubeErrorCode,
    check_pot_provider_health,
    get_pot_provider_url,
)
import yt_dlp.version
from fastapi.responses import JSONResponse

youtube_service = YouTubeService(DOWNLOAD_DIR)


@router.get("/youtube-health")
async def youtube_health():
    """Health check for YouTube extraction subsystem & PO-Token provider."""
    pot_url = get_pot_provider_url()
    pot_healthy = await check_pot_provider_health(pot_url)
    ffmpeg_path = youtube_service.find_ffmpeg_location()

    return {
        "status": "healthy" if pot_healthy else "degraded",
        "pot_provider_available": pot_healthy,
        "pot_provider_url": pot_url,
        "ytdlp_version": getattr(yt_dlp.version, "__version__", "unknown"),
        "ffmpeg_available": bool(ffmpeg_path),
    }


@router.post("/download-youtube")
async def download_youtube(req: DownloadRequest, background_tasks: BackgroundTasks):
    try:
        downloaded_file, display_filename = await youtube_service.download_video(req.url)
        
        # Schedule cleanup after streaming the file to the client
        background_tasks.add_task(cleanup_file, downloaded_file)
        
        return FileResponse(
            downloaded_file, 
            filename=display_filename,
            media_type="video/mp4"
        )
        
    except YouTubeExtractionError as yte:
        return JSONResponse(status_code=yte.status_code, content=yte.to_dict())
    except Exception as e:
        print(f"YouTube Download Unexpected Error: {e}")
        unknown_err = YouTubeExtractionError(YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR, "Unexpected server error during extraction.")
        return JSONResponse(status_code=500, content=unknown_err.to_dict())



from spotify_downloader import download_spotify_track

@router.post("/download-spotify")
async def download_spotify(req: DownloadRequest, background_tasks: BackgroundTasks):
    if not req.url or ("spotify.com" not in req.url and "spotify:" not in req.url):
        raise HTTPException(status_code=400, detail="Valid Spotify URL required")

    job_id = str(uuid.uuid4())
    
    try:
        downloaded_file = await asyncio.to_thread(
            download_spotify_track, 
            req.url, 
            DOWNLOAD_DIR, 
            None, 
            job_id
        )
        
        if not downloaded_file or not os.path.exists(downloaded_file):
            raise Exception("Downloaded audio file not found")
            
        background_tasks.add_task(cleanup_file, downloaded_file)
        
        filename = os.path.basename(downloaded_file)
        if filename.startswith(f"{job_id}_"):
            filename = filename[len(f"{job_id}_"):]
            
        return FileResponse(
            downloaded_file, 
            filename=filename,
            media_type="audio/mpeg"
        )
        
    except Exception as e:
        print(f"Spotify Download Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


from fastapi import UploadFile, File, Form
from spotify_downloader import find_ffmpeg_path

def get_ffmpeg_cmd():
    cmd = find_ffmpeg_path()
    return cmd if cmd else "ffmpeg"


@router.post("/convert-video")
async def convert_video(
    file: UploadFile = File(...),
    target_format: str = Form("mp4"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp4"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.{in_ext}")
    target_fmt = target_format.lower().replace(".", "")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_out.{target_fmt}")

    content = await file.read()
    with open(in_path, "wb") as f:
        f.write(content)

    ffmpeg = get_ffmpeg_cmd()
    try:
        if target_fmt == "gif":
            cmd = [ffmpeg, "-y", "-i", in_path, "-vf", "fps=10,scale=480:-1:flags=lanczos", out_path]
        elif target_fmt == "webm":
            cmd = [ffmpeg, "-y", "-i", in_path, "-c:v", "libvpx-vp9", "-crf", "30", "-b:v", "0", "-c:a", "libopus", out_path]
        elif target_fmt == "mov":
            cmd = [ffmpeg, "-y", "-i", in_path, "-c:v", "libx264", "-c:a", "aac", out_path]
        else: # mp4
            cmd = [ffmpeg, "-y", "-i", in_path, "-c:v", "libx264", "-c:a", "aac", "-movflags", "+faststart", out_path]

        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            if not os.path.exists(out_path):
                raise Exception(f"FFmpeg error: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        media_type = f"video/{target_fmt}" if target_fmt != "gif" else "image/gif"
        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(out_path, filename=f"{orig_stem}.{target_fmt}", media_type=media_type)
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Video conversion error: {str(e)}")


@router.post("/compress-video")
async def compress_video(
    file: UploadFile = File(...),
    preset: str = Form("medium"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp4"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.{in_ext}")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_compressed.{in_ext}")

    content = await file.read()
    with open(in_path, "wb") as f:
        f.write(content)

    crf = "28"
    if preset == "low":
        crf = "22"
    elif preset == "high":
        crf = "36"

    ffmpeg = get_ffmpeg_cmd()
    try:
        cmd = [ffmpeg, "-y", "-i", in_path, "-vcodec", "libx264", "-crf", crf, "-preset", "faster", "-acodec", "aac", "-b:a", "128k", out_path]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"FFmpeg compression error: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(out_path, filename=f"{orig_stem}_compressed.{in_ext}", media_type=f"video/{in_ext}")
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Video compression error: {str(e)}")


@router.post("/convert-audio")
async def convert_audio(
    file: UploadFile = File(...),
    target_format: str = Form("mp3"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp3"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.{in_ext}")
    target_fmt = target_format.lower().replace(".", "")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_out.{target_fmt}")

    content = await file.read()
    with open(in_path, "wb") as f:
        f.write(content)

    ffmpeg = get_ffmpeg_cmd()
    try:
        if target_fmt == "wav":
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "pcm_s16le", out_path]
        elif target_fmt == "ogg":
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "libvorbis", out_path]
        elif target_fmt == "aac" or target_fmt == "m4a":
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "aac", out_path]
        else: # mp3
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "libmp3lame", "-b:a", "192k", out_path]

        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"FFmpeg audio conversion error: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(out_path, filename=f"{orig_stem}.{target_fmt}", media_type=f"audio/{target_fmt}")
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Audio conversion error: {str(e)}")



