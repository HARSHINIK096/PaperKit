# YouTube PO-Token Extraction Subsystem Guide

This document details the production YouTube video extraction architecture, Proof-of-Origin (PO) Token provider lifecycle, readiness diagnostics, and troubleshooting procedures for PaperKit.

---

## 1. Architecture Overview

```text
Flutter App / API Client
      │
      ▼ (HTTP POST /api/media/download-youtube)
FastAPI Backend (routers/media.py -> services/youtube_service.py)
      │
      ├── Spawns & Manages Local PO-Token Server (pot_server/server.js) on 127.0.0.1:4416
      │
      ▼
yt-dlp Engine
      │
      ├── Discovers Plugin (yt_dlp_plugins.extractor.getpot_bgutil_http)
      │
      ▼
bgutil HTTP Provider Plugin (getpot_bgutil_http)
      │
      ├── Pings http://127.0.0.1:4416/ping
      ├── Requests Token via POST http://127.0.0.1:4416/get_pot
      │
      ▼
pot_server Node.js Service (express, bgutils-js, jsdom)
      │
      ├── Mints BotGuard / WebPo PO Token
      │
      ▼
yt-dlp Engine
      │
      ├── Attaches PO Token to InnerTube / mweb Client Requests
      │
      ▼
YouTube API & Media Streaming (HTTP 200 Success)
```

---

## 2. Dependencies & Runtime Requirements

1. **Python 3.10+** (with `yt-dlp[default]>=2025.1.15`, `yt-dlp-ejs`, `bgutil-ytdlp-pot-provider>=2.0.0`).
2. **Node.js LTS (v18+) & npm** (installed in system PATH or `./bin/node`).
3. **pot_server Node Dependencies** (`express`, `bgutils-js`, `jsdom`, `youtubei.js`).
4. **FFmpeg Binary** (located in system PATH or `./bin/ffmpeg`).

---

## 3. Health & Readiness Diagnostics

The endpoint `GET /api/media/youtube-health` provides detailed operational diagnostics:

```json
{
  "status": "healthy",
  "pot_provider_configured": true,
  "pot_provider_reachable": true,
  "pot_provider_operational": true,
  "pot_provider_available": true,
  "pot_provider_url": "http://127.0.0.1:4416",
  "node_available": true,
  "node_version": "v20.18.0",
  "ytdlp_version": "2026.08.19",
  "ffmpeg_available": true
}
```

### Diagnostic Definitions

- **`pot_provider_reachable`**: Tests `GET http://127.0.0.1:4416/ping`. Proves Express HTTP server is running.
- **`pot_provider_operational`**: Tests `POST http://127.0.0.1:4416/get_pot` with test video `_Wv9oLUe740`. Proves BotGuard JS execution and PO token minting work.
- **`node_available`**: Verified via `shutil.which("node")` or `./bin/node`.

---

## 4. Render Deployment

In Render's deployment environment:
1. `render-build.sh` automatically downloads standalone Node.js LTS into `bin/` if `node` is absent in PATH.
2. `render-build.sh` runs `npm install` inside `pot_server/`.
3. `main.py` prepends `bin/` to `PATH` and starts `pot_server/server.js` automatically during app lifespan.

---

## 5. Verification Commands

Run unit & extraction tests:
```bash
pytest -v
```

Test live YouTube extraction via API:
```bash
curl -X POST "http://127.0.0.1:8000/api/media/download-youtube" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://www.youtube.com/watch?v=_Wv9oLUe740"}'
```
