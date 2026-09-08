# PaperKit v1.5.6 Release

PaperKit **v1.5.6** brings backend reliability improvements, Render health check support, modernized frontend document workflows, Spotify downloader refactoring, and stability enhancements across both Android and Web platforms.

---

## 🚀 What's New & Fixed in v1.5.6

### 1. Backend & Render Cloud Stability
- **Probes & Health Checks**: Added `HEAD` request support for root and health check endpoints to satisfy Render/Uptime robot keep-alive pings.
- **Dependency Compatibility**: Upgraded `FastAPI` and `pydantic-settings` to resolve Pydantic v2 `FieldInfo` and `SettingsConfigDict` compatibility.
- **Python Runtime**: Pinned Python `3.11.9` and supplied safe default settings to avoid deployment crashes.
- **Test Suite**: Comprehensive test suite regeneration matching active router architecture and auth schemas.

### 2. Document & Media Services
- **Spotify & Media Downloader**: Refactored backend media pipeline for improved reliability and streaming.
- **Docx Preview & Processing**: Enhanced `.docx` client-side rendering with styling fidelity.
- **Capacitor Downloads**: Streamlined native filesystem file saving and previewing on Android.
- **AI Tools**: Polished Summarize PDF layout and responsive touch controls.

---

## 📦 Build & Release Artifacts

| Parameter | Value |
|---|---|
| **Version** | `1.5.6` |
| **Version Code** | `156` |
| **Release Artifact** | `PaperKit-v1.5.6.apk` (~31.4 MB) |
| **Tag** | `v1.5.6` |

---

## 📥 Installation

1. Download **`PaperKit-v1.5.6.apk`** from the release assets below.
2. Install the APK on your Android device (ensure *Install from Unknown Sources* is enabled if prompted).
3. Enjoy PaperKit v1.5.6!
