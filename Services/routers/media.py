import os
import re
import sys
import uuid
import json
import base64
import zipfile
import subprocess
import shutil
from typing import Optional, List
from fastapi import APIRouter, HTTPException, BackgroundTasks, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel

router = APIRouter()

# Directory setup for temporary downloads and frame extraction jobs
DOWNLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scratch", "downloads")
FRAMES_JOB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scratch", "frames")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(FRAMES_JOB_DIR, exist_ok=True)

MAX_VIDEO_DURATION_SECONDS = 180  # 3 minutes maximum to preserve Render CPU/memory
MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024  # 100 MB max input file size
MAX_EXTRACT_FRAMES = 300  # Max frames per job to prevent Render out-of-memory/disk fill


def cleanup_file(filepath: str):
    try:
        if os.path.exists(filepath):
            if os.path.isdir(filepath):
                shutil.rmtree(filepath, ignore_errors=True)
            else:
                os.remove(filepath)
    except Exception as e:
        print(f"Error cleaning up {filepath}: {e}")


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


def find_ffprobe_path() -> str:
    cmd = shutil.which("ffprobe")
    if cmd:
        return cmd
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    bin_ffprobe = os.path.join(base_dir, "bin", "ffprobe.exe" if sys.platform == "win32" else "ffprobe")
    if os.path.isfile(bin_ffprobe):
        return bin_ffprobe
    return "ffprobe"


def get_ffmpeg_cmd():
    cmd = find_ffmpeg_path()
    return cmd if cmd else "ffmpeg"


def get_ffprobe_cmd():
    cmd = find_ffprobe_path()
    return cmd if cmd else "ffprobe"


def find_system_font_path() -> Optional[str]:
    """Find a reliable TTF font on the host system for FFmpeg text overlay."""
    candidate_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\calibri.ttf",
        "C:\\Windows\\Fonts\\segoeui.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for p in candidate_paths:
        if os.path.isfile(p):
            return p
    return None


def probe_video_metadata(video_path: str) -> dict:
    """Run ffprobe to extract truthful duration, dimensions, fps, and format."""
    ffprobe = get_ffprobe_cmd()
    cmd = [
        ffprobe,
        "-v", "quiet",
        "-print_format", "json",
        "-show_format",
        "-show_streams",
        video_path,
    ]
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        if res.returncode != 0:
            return {}
        info = json.loads(res.stdout.decode("utf-8"))
        
        video_stream = None
        audio_stream = None
        for s in info.get("streams", []):
            if s.get("codec_type") == "video" and not video_stream:
                video_stream = s
            elif s.get("codec_type") == "audio" and not audio_stream:
                audio_stream = s

        fmt = info.get("format", {})
        duration = float(fmt.get("duration", 0.0) or 0.0)
        if duration == 0.0 and video_stream:
            duration = float(video_stream.get("duration", 0.0) or 0.0)

        width = int(video_stream.get("width", 0) if video_stream else 0)
        height = int(video_stream.get("height", 0) if video_stream else 0)

        fps = 0.0
        if video_stream:
            fps_str = video_stream.get("r_frame_rate", "0/0")
            if "/" in fps_str:
                num, den = fps_str.split("/")
                if float(den) > 0:
                    fps = round(float(num) / float(den), 2)
            else:
                fps = float(fps_str or 0.0)

        codec = video_stream.get("codec_name", "unknown") if video_stream else "unknown"
        size = int(fmt.get("size", os.path.getsize(video_path) if os.path.exists(video_path) else 0))

        return {
            "duration": round(duration, 2),
            "width": width,
            "height": height,
            "fps": fps,
            "codec": codec,
            "has_audio": audio_stream is not None,
            "size": size,
            "format_name": fmt.get("format_name", "mp4"),
            "safe_for_processing": duration <= MAX_VIDEO_DURATION_SECONDS and size <= MAX_FILE_SIZE_BYTES,
        }
    except Exception as e:
        print(f"Error probing video {video_path}: {e}")
        return {}


# ─────────────────────────────────────────────────────────────────────────────
# PART 1: VIDEO → FRAME EXTRACTION & VIDEO METADATA PROBE
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/video-info")
async def get_video_info(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    """Probe uploaded video for truthful metadata (duration, resolution, fps, file size)."""
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp4"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_probe.{in_ext}")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"Video size ({len(content)/(1024*1024):.1f} MB) exceeds maximum allowed size of 100 MB."
        )

    with open(in_path, "wb") as f:
        f.write(content)

    background_tasks.add_task(cleanup_file, in_path)

    meta = probe_video_metadata(in_path)
    if not meta:
        raise HTTPException(status_code=400, detail="Could not probe video file. File may be corrupted or in an unsupported format.")

    return {
        "filename": file.filename,
        "duration": meta["duration"],
        "width": meta["width"],
        "height": meta["height"],
        "fps": meta["fps"],
        "codec": meta["codec"],
        "has_audio": meta["has_audio"],
        "size": meta["size"],
        "format_name": meta["format_name"],
        "max_duration_seconds": MAX_VIDEO_DURATION_SECONDS,
        "max_file_size_mb": 100,
    }


@router.post("/video-extract-frames")
async def extract_video_frames(
    file: UploadFile = File(...),
    mode: str = Form("fps"),            # every_frame, fps, interval, timestamps
    fps: float = Form(1.0),
    interval: float = Form(1.0),
    timestamps: str = Form(""),         # Comma-separated timestamps in seconds or HH:MM:SS
    image_format: str = Form("jpg"),    # jpg, jpeg, png
    jpeg_quality: int = Form(85),       # 1 - 100
    png_compression: int = Form(6),     # 0 - 9
    as_zip: bool = Form(False),         # Return ZIP archive directly
    max_frames: int = Form(100),        # Guard limit
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    """Extract real frames from video using FFmpeg.
    
    Supports:
    - Mode A: Every frame (subject to safe frame threshold)
    - Mode B: Extract at FPS (1, 2, 5, 10, custom)
    - Mode C: Extract by Interval (every 1s, 2s, 5s, custom)
    - Mode D: Specific Timestamp(s)
    - Export as real JPG or PNG with quality controls
    - Thumbnail JSON output or full ZIP archive download
    """
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp4"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_in.{in_ext}")
    job_folder = os.path.join(FRAMES_JOB_DIR, f"job_{job_id}")
    os.makedirs(job_folder, exist_ok=True)

    content = await file.read()
    if len(content) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"Video file exceeds maximum allowed size of 100 MB."
        )

    with open(in_path, "wb") as f:
        f.write(content)

    meta = probe_video_metadata(in_path)
    duration = meta.get("duration", 0.0)
    video_fps = meta.get("fps", 30.0) or 30.0

    if duration > MAX_VIDEO_DURATION_SECONDS:
        cleanup_file(in_path)
        cleanup_file(job_folder)
        raise HTTPException(
            status_code=400,
            detail=f"Video duration ({duration:.1f}s) exceeds the safe processing limit of {MAX_VIDEO_DURATION_SECONDS}s. Please trim video first."
        )

    # Resource Protection: calculate expected frames
    mode = mode.lower().strip()
    expected_frames = 0
    if mode == "every_frame":
        expected_frames = int(duration * video_fps) if duration > 0 else 0
        if expected_frames > MAX_EXTRACT_FRAMES:
            cleanup_file(in_path)
            cleanup_file(job_folder)
            raise HTTPException(
                status_code=400,
                detail=f"Extracting every frame from this {duration:.1f}s video would generate ~{expected_frames} frames, exceeding the safe limit of {MAX_EXTRACT_FRAMES} frames. Please use 'Extract at FPS' (e.g. 1 or 2 FPS) or 'Extract by Interval'."
            )
    elif mode == "fps":
        if fps <= 0:
            fps = 1.0
        expected_frames = int(duration * fps) if duration > 0 else 0
        if expected_frames > MAX_EXTRACT_FRAMES:
            cleanup_file(in_path)
            cleanup_file(job_folder)
            raise HTTPException(
                status_code=400,
                detail=f"Requested FPS ({fps}) would produce ~{expected_frames} frames. Safe limit is {MAX_EXTRACT_FRAMES} frames."
            )
    elif mode == "interval":
        if interval <= 0:
            interval = 1.0
        expected_frames = int(duration / interval) if duration > 0 else 0

    # Image format settings
    img_fmt = "jpg" if image_format.lower() in ["jpg", "jpeg"] else "png"
    quality_args = []
    if img_fmt == "jpg":
        # FFmpeg q:v for mjpeg: 1 is best, 31 is worst
        qscale = max(1, min(31, int((100 - max(1, min(100, jpeg_quality))) * 0.3 + 1)))
        quality_args = ["-q:v", str(qscale)]
    else:
        comp = max(0, min(9, png_compression))
        quality_args = ["-compression_level", str(comp)]

    ffmpeg = get_ffmpeg_cmd()

    try:
        if mode == "timestamps" and timestamps.strip():
            # Extract at individual timestamps
            raw_ts = [t.strip() for t in timestamps.split(",") if t.strip()]
            for idx, t_str in enumerate(raw_ts[:MAX_EXTRACT_FRAMES]):
                out_frame = os.path.join(job_folder, f"frame_{idx+1:06d}.{img_fmt}")
                cmd = [ffmpeg, "-y", "-ss", t_str, "-i", in_path, "-vframes", "1"] + quality_args + [out_frame]
                subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
        else:
            # Mode A, B, or C
            vf_filter = []
            if mode == "fps":
                vf_filter = ["-vf", f"fps={fps}"]
            elif mode == "interval":
                vf_filter = ["-vf", f"fps=1/{interval}"]

            out_pattern = os.path.join(job_folder, f"frame_%06d.{img_fmt}")
            cmd = [ffmpeg, "-y", "-i", in_path] + vf_filter + quality_args + [out_pattern]
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90)
            if res.returncode != 0:
                raise Exception(f"FFmpeg extraction failed: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        # Gather extracted frame files
        extracted_files = sorted([
            f for f in os.listdir(job_folder)
            if f.startswith("frame_") and f.endswith(f".{img_fmt}")
        ])

        if not extracted_files:
            raise Exception("No frames could be extracted from video.")

        # Create ZIP archive
        zip_path = os.path.join(FRAMES_JOB_DIR, f"{job_id}_frames.zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for f in extracted_files:
                fpath = os.path.join(job_folder, f)
                zf.write(fpath, arcname=f)

        cleanup_file(in_path)

        # If user explicitly requested direct ZIP download
        if as_zip:
            background_tasks.add_task(cleanup_file, zip_path)
            background_tasks.add_task(cleanup_file, job_folder)
            orig_stem = file.filename.rsplit(".", 1)[0]
            return FileResponse(
                zip_path,
                filename=f"{orig_stem}_frames.zip",
                media_type="application/zip",
            )

        # Build JSON metadata list with base64 data URLs for instant client thumbnail rendering
        frames_meta = []
        for idx, f in enumerate(extracted_files):
            fpath = os.path.join(job_folder, f)
            fsize = os.path.getsize(fpath)
            
            # Approximate timestamp
            ts_sec = 0.0
            if mode == "fps" and fps > 0:
                ts_sec = round(idx / fps, 2)
            elif mode == "interval":
                ts_sec = round(idx * interval, 2)
            elif mode == "every_frame" and video_fps > 0:
                ts_sec = round(idx / video_fps, 2)

            # Generate base64 data URL for fast, lossless thumbnail preview
            with open(fpath, "rb") as img_file:
                b64 = base64.b64encode(img_file.read()).decode("utf-8")
            mime = "image/jpeg" if img_fmt == "jpg" else "image/png"
            data_url = f"data:{mime};base64,{b64}"

            frames_meta.append({
                "frame_number": idx + 1,
                "timestamp_sec": ts_sec,
                "filename": f,
                "file_size": fsize,
                "data_url": data_url,
                "download_url": f"/media/video-frames/{job_id}/frame/{idx+1}",
            })

        return {
            "success": True,
            "job_id": job_id,
            "total_frames": len(extracted_files),
            "image_format": img_fmt,
            "width": meta.get("width", 0),
            "height": meta.get("height", 0),
            "frames": frames_meta,
            "zip_url": f"/media/video-frames/{job_id}/zip",
        }

    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(job_folder)
        raise HTTPException(status_code=500, detail=f"Frame extraction error: {str(e)}")


@router.get("/video-frames/{job_id}/zip")
async def download_frames_zip(
    job_id: str,
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    """Download full ZIP archive of extracted frames for a job."""
    zip_path = os.path.join(FRAMES_JOB_DIR, f"{job_id}_frames.zip")
    if not os.path.exists(zip_path):
        raise HTTPException(status_code=404, detail="ZIP archive not found or expired.")

    return FileResponse(
        zip_path,
        filename="video_frames.zip",
        media_type="application/zip",
    )


@router.get("/video-frames/{job_id}/frame/{frame_idx}")
async def download_single_frame(job_id: str, frame_idx: int):
    """Download a single extracted frame image."""
    job_folder = os.path.join(FRAMES_JOB_DIR, f"job_{job_id}")
    if not os.path.exists(job_folder):
        raise HTTPException(status_code=404, detail="Frame job not found or expired.")

    target_name = f"frame_{frame_idx:06d}"
    for f in os.listdir(job_folder):
        if f.startswith(target_name):
            fpath = os.path.join(job_folder, f)
            mime = "image/jpeg" if f.endswith((".jpg", ".jpeg")) else "image/png"
            return FileResponse(fpath, filename=f, media_type=mime)

    raise HTTPException(status_code=404, detail=f"Frame {frame_idx} not found.")


# ─────────────────────────────────────────────────────────────────────────────
# PART 2: LIGHTWEIGHT RENDER-COMPATIBLE VIDEO EDITOR
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/video-edit")
async def edit_video(
    file: UploadFile = File(...),
    start_time: float = Form(0.0),
    end_time: float = Form(0.0),
    crop_preset: str = Form("original"),    # original, 1:1, 4:5, 16:9, 9:16, 4:3
    rotation: int = Form(0),                # 0, 90, 180, 270
    flip_h: bool = Form(False),
    flip_v: bool = Form(False),
    speed: float = Form(1.0),               # 0.5 to 2.0
    volume: float = Form(1.0),              # 0.0 to 2.0
    mute: bool = Form(False),
    fade_in: float = Form(0.0),             # Audio fade in (seconds)
    fade_out: float = Form(0.0),            # Audio fade out (seconds)
    filter_preset: str = Form("none"),      # none, grayscale, bright, contrast, sharpen, blur
    text_overlay: str = Form(""),
    text_position: str = Form("bottom"),    # top, center, bottom
    text_size: int = Form(24),
    text_color: str = Form("white"),
    export_resolution: str = Form("original"), # original, 1080p, 720p, 480p
    export_crf: int = Form(23),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    """Execute lightweight Render-compatible video editing operations.
    
    Reliably executes:
    - Trim & Cut
    - Aspect Ratio Crop (1:1, 4:5, 16:9, 9:16, 4:3)
    - Rotate (90 CW, 90 CCW, 180) & Flip (H/V)
    - Speed adjustment (0.5x - 2.0x)
    - Volume control, Mute, Audio Fade-In/Out
    - Color adjustments (Grayscale, Brightness, Contrast, Sharpen, Blur)
    - Safe Text Overlay with verified font fallback
    - MP4 Export with resolution & CRF controls
    """
    job_id = str(uuid.uuid4())
    in_ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "mp4"
    in_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_edit_in.{in_ext}")
    out_path = os.path.join(DOWNLOAD_DIR, f"{job_id}_edited.mp4")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Video exceeds maximum allowed size of 100 MB.")

    with open(in_path, "wb") as f:
        f.write(content)

    meta = probe_video_metadata(in_path)
    duration = meta.get("duration", 0.0)

    if duration > MAX_VIDEO_DURATION_SECONDS:
        cleanup_file(in_path)
        raise HTTPException(
            status_code=400,
            detail=f"Video duration ({duration:.1f}s) exceeds the safe limit of {MAX_VIDEO_DURATION_SECONDS}s."
        )

    # Build FFmpeg command
    ffmpeg = get_ffmpeg_cmd()
    cmd = [ffmpeg, "-y"]

    # 1. Trim inputs
    if start_time > 0.0:
        cmd += ["-ss", str(start_time)]
    if end_time > 0.0 and end_time > start_time:
        cmd += ["-to", str(end_time)]

    cmd += ["-i", in_path]

    # 2. Build Video Filter Chain
    vf_chain = []

    # Rotation and Flip
    if rotation == 90:
        vf_chain.append("transpose=1")
    elif rotation == 180:
        vf_chain.append("transpose=1,transpose=1")
    elif rotation == 270:
        vf_chain.append("transpose=2")

    if flip_h:
        vf_chain.append("hflip")
    if flip_v:
        vf_chain.append("vflip")

    # Crop presets
    crop_preset = crop_preset.lower().strip()
    if crop_preset == "1:1":
        vf_chain.append("crop=min(iw\\,ih):min(iw\\,ih)")
    elif crop_preset == "4:5":
        vf_chain.append("crop=ih*4/5:ih")
    elif crop_preset == "16:9":
        vf_chain.append("crop=iw:iw*9/16")
    elif crop_preset == "9:16":
        vf_chain.append("crop=ih*9/16:ih")
    elif crop_preset == "4:3":
        vf_chain.append("crop=ih*4/3:ih")

    # Speed
    if speed > 0 and speed != 1.0:
        speed = max(0.5, min(2.0, speed))
        vf_chain.append(f"setpts={1.0/speed:.4f}*PTS")

    # Color Filters
    filter_preset = filter_preset.lower().strip()
    if filter_preset == "grayscale":
        vf_chain.append("hue=s=0")
    elif filter_preset == "bright":
        vf_chain.append("eq=brightness=0.12:contrast=1.1")
    elif filter_preset == "contrast":
        vf_chain.append("eq=contrast=1.35:saturation=1.2")
    elif filter_preset == "sharpen":
        vf_chain.append("unsharp=5:5:1.0:5:5:0.0")
    elif filter_preset == "blur":
        vf_chain.append("boxblur=4:1")

    # Text Overlay with safe font selection
    if text_overlay and text_overlay.strip():
        clean_text = re.sub(r"[^a-zA-Z0-9 .,!?_\-+=#@%]", "", text_overlay.strip())
        if clean_text:
            pos_x = "(w-text_w)/2"
            pos_y = "h-text_h-30"
            if text_position == "top":
                pos_y = "30"
            elif text_position == "center":
                pos_y = "(h-text_h)/2"

            font_path = find_system_font_path()
            font_arg = ""
            if font_path and not sys.platform.startswith("win"):
                font_arg = f":fontfile='{font_path}'"
            t_size = max(12, min(72, text_size))
            t_color = "white" if text_color.lower() not in ["yellow", "red", "cyan", "green", "black"] else text_color.lower()
            
            drawtext_str = f"drawtext=text='{clean_text}'{font_arg}:fontsize={t_size}:fontcolor={t_color}:box=1:boxcolor=black@0.5:boxborderw=6:x={pos_x}:y={pos_y}"
            vf_chain.append(drawtext_str)

    # Resolution scaling
    export_resolution = export_resolution.lower().strip()
    if export_resolution == "1080p":
        vf_chain.append("scale=-2:1080")
    elif export_resolution == "720p":
        vf_chain.append("scale=-2:720")
    elif export_resolution == "480p":
        vf_chain.append("scale=-2:480")

    if vf_chain:
        cmd += ["-vf", ",".join(vf_chain)]

    # 3. Audio Processing
    if mute or not meta.get("has_audio", True):
        cmd.append("-an")
    else:
        af_chain = []
        if speed > 0 and speed != 1.0:
            af_chain.append(f"atempo={speed:.4f}")
        if volume != 1.0 and volume >= 0.0:
            vol_val = max(0.0, min(2.0, volume))
            af_chain.append(f"volume={vol_val:.2f}")
        if fade_in > 0:
            af_chain.append(f"afade=t=in:ss=0:d={fade_in:.2f}")
        if fade_out > 0:
            effective_duration = (end_time if end_time > 0 else duration) - start_time
            if effective_duration > fade_out:
                af_chain.append(f"afade=t=out:st={effective_duration - fade_out:.2f}:d={fade_out:.2f}")

        if af_chain:
            cmd += ["-af", ",".join(af_chain)]
        cmd += ["-c:a", "aac", "-b:a", "128k"]

    # 4. Encoding parameters for fast Render export
    crf_val = str(max(18, min(32, export_crf)))
    cmd += [
        "-c:v", "libx264",
        "-crf", crf_val,
        "-preset", "faster",
        "-movflags", "+faststart",
        out_path
    ]

    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"Video editing failed: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        orig_stem = file.filename.rsplit(".", 1)[0]
        return FileResponse(
            out_path,
            filename=f"{orig_stem}_edited.mp4",
            media_type="video/mp4",
            headers={"Content-Disposition": f'attachment; filename="{orig_stem}_edited.mp4"'}
        )
    except Exception as e:
        cleanup_file(in_path)
        cleanup_file(out_path)
        raise HTTPException(status_code=500, detail=f"Video editor processing error: {str(e)}")


# ─────────────────────────────────────────────────────────────────────────────
# EXISTING MEDIA CONVERTER, COMPRESSOR, AUDIO TOOLS
# ─────────────────────────────────────────────────────────────────────────────

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
        elif target_fmt in ["mp3", "wav", "aac", "m4a", "flac", "ogg"]:
            cmd = [ffmpeg, "-y", "-i", in_path, "-vn", out_path]
        else: # mp4, avi, mkv, flv, wmv, 3gp, ogv, ts
            cmd = [ffmpeg, "-y", "-i", in_path, "-c:v", "libx264", "-c:a", "aac", "-movflags", "+faststart", out_path]

        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0 or not os.path.exists(out_path):
            raise Exception(f"FFmpeg error: {res.stderr.decode('utf-8', errors='ignore')[:300]}")

        background_tasks.add_task(cleanup_file, in_path)
        background_tasks.add_task(cleanup_file, out_path)

        media_type = f"audio/{target_fmt}" if target_fmt in ["mp3", "wav", "aac", "m4a", "flac", "ogg"] else (f"video/{target_fmt}" if target_fmt != "gif" else "image/gif")
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
    vf_flags = []
    if preset == "low":
        crf = "22"
    elif preset == "high":
        crf = "34"
    elif preset == "extreme":
        crf = "40"
    elif preset == "720p":
        crf = "26"
        vf_flags = ["-vf", "scale=-2:720"]
    elif preset == "480p":
        crf = "28"
        vf_flags = ["-vf", "scale=-2:480"]

    ffmpeg = get_ffmpeg_cmd()
    try:
        cmd = [ffmpeg, "-y", "-i", in_path] + vf_flags + ["-vcodec", "libx264", "-crf", crf, "-preset", "faster", "-acodec", "aac", "-b:a", "128k", out_path]
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
        elif target_fmt in ["ogg", "opus"]:
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "libvorbis", out_path]
        elif target_fmt == "flac":
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "flac", out_path]
        elif target_fmt in ["aac", "m4a"]:
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "aac", out_path]
        elif target_fmt == "amr":
            cmd = [ffmpeg, "-y", "-i", in_path, "-acodec", "libopencore_amrnb", "-ar", "8000", "-ac", "1", out_path]
        else: # mp3, wma, aiff, etc.
            cmd = [ffmpeg, "-y", "-i", in_path, out_path]

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
