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

@router.post("/download-youtube")
async def download_youtube(req: DownloadRequest, background_tasks: BackgroundTasks):
    if not req.url or ("youtube.com" not in req.url and "youtu.be" not in req.url):
        raise HTTPException(status_code=400, detail="Valid YouTube URL required")

    job_id = str(uuid.uuid4())
    output_template = os.path.join(DOWNLOAD_DIR, f"{job_id}_%(title)s.%(ext)s")
    
    try:
        bin_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "bin")
        
        ydl_opts = {
            'outtmpl': output_template,
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'merge_output_format': 'mp4',
            'quiet': True,
            'no_warnings': True,
            'extractor_args': {
                'youtube': {
                    'player_client': ['android', 'web', 'ios'],
                }
            },
            'http_headers': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            }
        }
        
        if os.path.exists(bin_dir):
            ydl_opts['ffmpeg_location'] = bin_dir
            
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([req.url])
            
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
        downloaded_file = download_spotify_track(req.url, output_dir=DOWNLOAD_DIR, job_id=job_id)
        
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


