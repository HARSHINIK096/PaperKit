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

def _sync_download_youtube(url: str, output_template: str, bin_dir: str):
    cookie_file = get_or_create_cookie_file(DOWNLOAD_DIR)
    ffmpeg_bin = find_ffmpeg_path()
    
    if cookie_file and os.path.exists(cookie_file):
        client_strategies = [
            None,
            ['web'],
            ['mweb'],
            ['android', 'ios'],
            ['android_vr', 'mweb'],
            ['ios'],
        ]
    else:
        client_strategies = [
            None,
            ['android', 'ios'],
            ['android_vr', 'mweb'],
            ['ios', 'mweb'],
            ['web'],
        ]

    proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")

    last_error = None
    for clients in client_strategies:
        ydl_opts = {
            'outtmpl': output_template,
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/bestvideo+bestaudio/best',
            'merge_output_format': 'mp4',
            'quiet': False,
            'no_warnings': True,
            'nocheckcertificate': True,
            'ignoreerrors': False,
            'http_headers': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            }
        }
        if proxy_url:
            ydl_opts['proxy'] = proxy_url
        if clients is not None:
            ydl_opts['extractor_args'] = {
                'youtube': {
                    'player_client': clients,
                }
            }
        if ffmpeg_bin:
            ydl_opts['ffmpeg_location'] = os.path.dirname(ffmpeg_bin) if os.path.isfile(ffmpeg_bin) else ffmpeg_bin
        elif os.path.exists(bin_dir):
            ydl_opts['ffmpeg_location'] = bin_dir
        if cookie_file and os.path.exists(cookie_file):
            ydl_opts['cookiefile'] = cookie_file

        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            return  # Succeeded
        except Exception as e:
            last_error = e
            print(f"yt-dlp attempt with clients {clients} failed: {e}. Trying next strategy...")
            continue

    if last_error:
        raise last_error

@router.post("/download-youtube")
async def download_youtube(req: DownloadRequest, background_tasks: BackgroundTasks):
    if not req.url or ("youtube.com" not in req.url and "youtu.be" not in req.url):
        raise HTTPException(status_code=400, detail="Valid YouTube URL required")

    job_id = str(uuid.uuid4())
    output_template = os.path.join(DOWNLOAD_DIR, f"{job_id}_%(title)s.%(ext)s")
    bin_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "bin")
    
    try:
        await asyncio.to_thread(_sync_download_youtube, req.url, output_template, bin_dir)
            
        # Find the downloaded file
        downloaded_file = None
        for filename in os.listdir(DOWNLOAD_DIR):
            if filename.startswith(job_id):
                downloaded_file = os.path.join(DOWNLOAD_DIR, filename)
                break
                
        if not downloaded_file:
            files = [os.path.join(DOWNLOAD_DIR, f) for f in os.listdir(DOWNLOAD_DIR) if os.path.isfile(os.path.join(DOWNLOAD_DIR, f))]
            if files:
                downloaded_file = max(files, key=os.path.getctime)

        if not downloaded_file or not os.path.exists(downloaded_file):
            raise Exception("Downloaded file not found")
            
        # Schedule cleanup after sending response
        background_tasks.add_task(cleanup_file, downloaded_file)
        
        return FileResponse(
            downloaded_file, 
            filename=os.path.basename(downloaded_file).replace(f"{job_id}_", ""),
            media_type="video/mp4"
        )
        
    except Exception as e:
        print(f"YouTube Download Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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



