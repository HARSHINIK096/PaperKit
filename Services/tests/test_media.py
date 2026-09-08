"""Media Downloader Router Test Suite (YouTube & Spotify)"""
import pytest
import os
import tempfile
from unittest.mock import patch


@pytest.mark.asyncio
async def test_youtube_invalid_url(client):
    """POST /api/media/download-youtube rejects invalid or missing YouTube URL."""
    resp = await client.post("/api/media/download-youtube", json={"url": "https://example.com/video"})
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_spotify_invalid_url(client):
    """POST /api/media/download-spotify rejects non-Spotify URL."""
    resp = await client.post("/api/media/download-spotify", json={"url": "https://example.com/audio"})
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_spotify_download_mocked(client):
    """POST /api/media/download-spotify dispatches and returns MP3 audio file."""
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp.write(b"ID3\x03\x00\x00\x00\x00\x00\x00" + b"\x00" * 1024)
        mock_file_path = tmp.name

    try:
        with patch("routers.media.download_spotify_track", return_value=mock_file_path):
            resp = await client.post(
                "/api/media/download-spotify",
                json={"url": "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT"},
            )
            assert resp.status_code == 200
            assert resp.headers.get("content-type") == "audio/mpeg"
    finally:
        if os.path.exists(mock_file_path):
            try:
                os.remove(mock_file_path)
            except OSError:
                pass


@pytest.mark.asyncio
async def test_spotify_metadata_resolver():
    """Verify Spotify metadata extraction."""
    from spotify_downloader import extract_spotify_metadata
    title, artists = extract_spotify_metadata("https://open.spotify.com/track/6jJHYbJReFfR2ieGzRP5bq")
    assert title is not None
    assert len(title) > 0
