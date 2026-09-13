"""Integration tests for Video Probe, Frame Extraction, and Lightweight Video Editor."""
import os
import subprocess
import pytest
import zipfile
from httpx import AsyncClient, ASGITransport
from main import app
from routers.media import get_ffmpeg_cmd, DOWNLOAD_DIR


@pytest.fixture(scope="module")
def sample_test_video():
    """Generate a minimal real 2-second MP4 test video with video and audio streams."""
    ffmpeg = get_ffmpeg_cmd()
    video_path = os.path.join(DOWNLOAD_DIR, "test_synth_video.mp4")
    cmd = [
        ffmpeg, "-y",
        "-f", "lavfi", "-i", "testsrc=duration=2:size=320x240:rate=10",
        "-f", "lavfi", "-i", "sine=frequency=1000:duration=2",
        "-c:v", "libx264", "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-t", "2",
        video_path
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert res.returncode == 0 and os.path.exists(video_path), "Failed to generate synthetic test video"
    yield video_path
    if os.path.exists(video_path):
        try:
            os.remove(video_path)
        except Exception:
            pass


@pytest.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_video_info_probe(async_client, sample_test_video):
    with open(sample_test_video, "rb") as f:
        files = {"file": ("test.mp4", f, "video/mp4")}
        res = await async_client.post("/media/video-info", files=files)

    assert res.status_code == 200, res.text
    data = res.json()
    assert data["filename"] == "test.mp4"
    assert data["width"] == 320
    assert data["height"] == 240
    assert 1.9 <= data["duration"] <= 2.1
    assert data["fps"] == 10.0
    assert data["has_audio"] is True


@pytest.mark.asyncio
async def test_video_frame_extraction_fps_jpg(async_client, sample_test_video):
    with open(sample_test_video, "rb") as f:
        files = {"file": ("test.mp4", f, "video/mp4")}
        data = {
            "mode": "fps",
            "fps": "2.0",
            "image_format": "jpg",
            "jpeg_quality": "80",
            "as_zip": "false"
        }
        res = await async_client.post("/media/video-extract-frames", files=files, data=data)

    assert res.status_code == 200, res.text
    result = res.json()
    assert result["success"] is True
    assert result["image_format"] == "jpg"
    assert len(result["frames"]) >= 3  # 2s * 2fps = 4 frames
    first_frame = result["frames"][0]
    assert first_frame["filename"].endswith(".jpg")
    assert first_frame["data_url"].startswith("data:image/jpeg;base64,")
    assert "download_url" in first_frame

    # Test downloading individual frame
    frame_dl_url = first_frame["download_url"]
    f_res = await async_client.get(frame_dl_url)
    assert f_res.status_code == 200
    assert f_res.headers.get("content-type") == "image/jpeg"
    assert len(f_res.content) > 100

    # Test downloading full ZIP
    zip_dl_url = result["zip_url"]
    z_res = await async_client.get(zip_dl_url)
    assert z_res.status_code == 200
    assert z_res.headers.get("content-type") == "application/zip"


@pytest.mark.asyncio
async def test_video_frame_extraction_png_direct_zip(async_client, sample_test_video):
    with open(sample_test_video, "rb") as f:
        files = {"file": ("test.mp4", f, "video/mp4")}
        data = {
            "mode": "interval",
            "interval": "1.0",
            "image_format": "png",
            "png_compression": "6",
            "as_zip": "true"
        }
        res = await async_client.post("/media/video-extract-frames", files=files, data=data)

    assert res.status_code == 200, res.text
    assert res.headers.get("content-type") == "application/zip"
    assert "attachment" in res.headers.get("content-disposition", "")
    assert len(res.content) > 200


@pytest.mark.asyncio
async def test_video_editor_pipeline(async_client, sample_test_video):
    with open(sample_test_video, "rb") as f:
        files = {"file": ("test.mp4", f, "video/mp4")}
        data = {
            "start_time": "0.0",
            "end_time": "1.0",
            "crop_preset": "1:1",
            "rotation": "90",
            "flip_h": "false",
            "speed": "1.5",
            "volume": "0.8",
            "filter_preset": "grayscale",
            "text_overlay": "MaskerV Test",
            "text_position": "bottom",
            "export_resolution": "480p",
            "export_crf": "26"
        }
        res = await async_client.post("/media/video-edit", files=files, data=data)

    assert res.status_code == 200, res.text
    assert res.headers.get("content-type") == "video/mp4"
    assert len(res.content) > 1000
    assert "attachment" in res.headers.get("content-disposition", "")
