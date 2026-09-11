import os
import sys
import uuid
import subprocess
import shutil
from fastapi import APIRouter, HTTPException, BackgroundTasks, UploadFile, File, Form
from fastapi.responses import FileResponse
from pydantic import BaseModel

router = APIRouter()

# Use the scratch folder or temp dir to store downloads/conversions temporarily
DOWNLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scratch", "downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

def cleanup_file(filepath: str):
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
    except Exception as e:
        print(f"Error cleaning up file {filepath}: {e}")

def find_ffmpeg_path() -> str:
    cmd = shutil.which("ffmpeg")
    if cmd:
        return cmd
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    bin_ffmpeg = os.path.join(base_dir, "bin", "ffmpeg.exe" if sys.platform == "win32" else "ffmpeg")
    if os.path.isfile(bin_ffmpeg):
        return bin_ffmpeg
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        pass
    return "ffmpeg"

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


@router.post("/audio/speed-pitch")
async def audio_speed_pitch(
    file: UploadFile = File(...),
    speed: float = Form(1.25),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    job_id = str(uuid.uuid4())
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.mp3")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_speed.mp3")

    content = await file.read()
    with open(in_path, "wb") as f:
        f.write(content)

    ffmpeg = get_ffmpeg_cmd()
    try:
        filter_str = f"atempo={speed}"
        cmd = [ffmpeg, "-y", "-i", in_path, "-filter:a", filter_str, "-vn", out_path]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"FFmpeg speed adjustment failed")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(out_path, filename=f"{orig_stem}_speed_{speed}.mp3", media_type="audio/mp3")
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Audio speed error: {str(e)}")


@router.post("/video/strip-audio")
async def video_strip_audio(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    job_id = str(uuid.uuid4())
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.mp4")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_audio.mp3")

    content = await file.read()
    with open(in_path, "wb") as f:
        f.write(content)

    ffmpeg = get_ffmpeg_cmd()
    try:
        cmd = [ffmpeg, "-y", "-i", in_path, "-vn", "-acodec", "libmp3lame", "-b:a", "192k", out_path]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"FFmpeg audio extraction failed")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(out_path, filename=f"{orig_stem}_extracted.mp3", media_type="audio/mp3")
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Video audio extraction error: {str(e)}")





