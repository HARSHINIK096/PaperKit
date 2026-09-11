"""
Test Suite for YouTube PO-Token Extraction Architecture & Error Model
"""
import pytest
import os
import asyncio
from unittest.mock import patch, MagicMock
from services.youtube_service import (
    YouTubeService,
    YouTubeExtractionError,
    YouTubeErrorCode,
    ERROR_STATUS_MAP,
    validate_and_normalize_youtube_url,
    classify_yt_dlp_error,
    check_pot_provider_health,
)


def test_youtube_url_validation_valid():
    """Test standard valid YouTube URLs are normalized to canonical format."""
    valid_urls = [
        ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("http://youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("https://youtu.be/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("https://m.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("https://www.youtube.com/shorts/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("https://www.youtube.com/embed/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10s&ab_channel=Artist", "dQw4w9WgXcQ"),
    ]
    for url, expected_id in valid_urls:
        canonical, vid = validate_and_normalize_youtube_url(url)
        assert vid == expected_id
        assert canonical == f"https://www.youtube.com/watch?v={expected_id}"


def test_youtube_url_validation_invalid():
    """Test invalid or malicious URLs raise YOUTUBE_URL_INVALID."""
    invalid_urls = [
        "",
        "https://example.com/video",
        "https://youtube.com/watch?v=short",
        "https://youtube.com/watch?v=toolongvideoid123456",
        "file:///etc/passwd",
        "ftp://youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtube.com/watch?v=dQw4w9WgXcQ; rm -rf /",
        "https://youtube.com/watch?v=dQw4w9WgXcQ | cat",
    ]
    for url in invalid_urls:
        with pytest.raises(YouTubeExtractionError) as exc_info:
            validate_and_normalize_youtube_url(url)
        assert exc_info.value.code == YouTubeErrorCode.YOUTUBE_URL_INVALID
        assert exc_info.value.status_code == 400



def test_error_classification():
    """Test yt-dlp error string classification into structured errors."""
    cases = [
        (Exception("Sign in to confirm you’re not a bot"), YouTubeErrorCode.YOUTUBE_BOT_PROTECTION),
        (Exception("Sign in to confirm you're not a bot"), YouTubeErrorCode.YOUTUBE_BOT_PROTECTION),
        (Exception("This video is private"), YouTubeErrorCode.YOUTUBE_PRIVATE_VIDEO),
        (Exception("Private video. Sign in if you've been granted access"), YouTubeErrorCode.YOUTUBE_PRIVATE_VIDEO),
        (Exception("This video is available to members only"), YouTubeErrorCode.YOUTUBE_AUTH_REQUIRED),
        (Exception("Video unavailable. This video does not exist"), YouTubeErrorCode.YOUTUBE_VIDEO_UNAVAILABLE),
        (Exception("The uploader has not made this video available in your country"), YouTubeErrorCode.YOUTUBE_REGION_RESTRICTED),
        (Exception("Requested format is not available"), YouTubeErrorCode.YOUTUBE_FORMAT_UNAVAILABLE),
        (Exception("Connection reset by peer: unable to download webpage"), YouTubeErrorCode.YOUTUBE_NETWORK_ERROR),
        (Exception("Some completely unrecognized error"), YouTubeErrorCode.YOUTUBE_UNKNOWN_ERROR),
    ]
    for exc, expected_code in cases:
        classified = classify_yt_dlp_error(exc)
        assert classified.code == expected_code
        assert classified.status_code == ERROR_STATUS_MAP[expected_code]


@pytest.mark.asyncio
async def test_youtube_health_endpoint(client):
    """GET /api/media/youtube-health returns subsystem status."""
    resp = await client.get("/api/media/youtube-health")
    assert resp.status_code == 200
    data = resp.json()
    assert "status" in data
    assert "pot_provider_available" in data
    assert "ytdlp_version" in data
    assert "ffmpeg_available" in data


@pytest.mark.asyncio
async def test_api_health_endpoint(client):
    """GET /health returns API status and youtube extraction subsystem state."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert "youtube_extraction" in data


@pytest.mark.asyncio
async def test_download_youtube_invalid_url_api(client):
    """POST /api/media/download-youtube with invalid URL returns HTTP 400 with structured JSON."""
    resp = await client.post("/api/media/download-youtube", json={"url": "https://example.com/not-youtube"})
    assert resp.status_code == 400
    data = resp.json()
    assert data["error_code"] == "YOUTUBE_URL_INVALID"
    assert "message" in data


@pytest.mark.asyncio
async def test_download_youtube_timeout_control(tmp_path):
    """Verify extraction timeout halts bounded extraction and raises YOUTUBE_EXTRACTION_TIMEOUT."""
    service = YouTubeService(str(tmp_path))
    service.max_extraction_seconds = 1  # 1 second timeout

    def slow_extract(*args, **kwargs):
        import time
        time.sleep(3)

    with patch.object(service, "_sync_extract", side_effect=slow_extract):
        with pytest.raises(YouTubeExtractionError) as exc_info:
            await service.download_video("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        assert exc_info.value.code == YouTubeErrorCode.YOUTUBE_EXTRACTION_TIMEOUT
        assert exc_info.value.status_code == 504


@pytest.mark.asyncio
async def test_unavailable_video_rejection(tmp_path):
    """Verify non-existent/unavailable YouTube video raises YOUTUBE_VIDEO_UNAVAILABLE."""
    service = YouTubeService(str(tmp_path))
    service.max_extraction_seconds = 45
    with pytest.raises(YouTubeExtractionError) as exc_info:
        await service.download_video("https://www.youtube.com/watch?v=BaW_jenozKc")
    assert exc_info.value.code == YouTubeErrorCode.YOUTUBE_VIDEO_UNAVAILABLE
    assert exc_info.value.status_code == 404


@pytest.mark.asyncio
async def test_live_public_video_download(tmp_path):
    """Verify real public YouTube video download using PO-token provider."""
    service = YouTubeService(str(tmp_path))
    service.max_extraction_seconds = 60
    file_path, display_name = await service.download_video("https://www.youtube.com/watch?v=jNQXAC9IVRw")
    assert os.path.isfile(file_path)
    assert os.path.getsize(file_path) > 1024
    assert display_name.endswith(".mp4")
    # Clean up
    if os.path.exists(file_path):
        os.remove(file_path)



