"""Media Router Test Suite (Video/Audio Conversion & Compression)"""
import pytest
import os


@pytest.mark.asyncio
async def test_media_router_online():
    """Basic sanity check for media router import."""
    from routers.media import router
    assert router is not None
