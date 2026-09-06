# PaperKit v7.3.2 — In-Place PDF Editor, Image Adjuster & Release Suite

We are excited to announce **PaperKit v7.3.2**! This release introduces our self-hosted **In-Place PDF Object & Text Editor Module**, a new client-side **Image Adjuster & Manipulator**, an **Exclusive Available Tools** sidebar navigation layout, headless Render deployment fixes, and complete synchronization across web and Android.

---

## 🚀 What's New in v7.3.2

### 1. In-Place PDF Object & Text Editor Module (`/tools/pdf-editor`)
- **Self-Hosted Redact & Overlay Engine**: Built using PyMuPDF (`fitz`) to cleanly erase target text bounding boxes (`add_redact_annot` + `apply_redactions`) and insert replacement text / image overlays without corrupting embedded fonts.
- **Interactive Canvas Overlay**: Renders PDF pages using `pdfjs-dist` to HTML5 canvas and extracts text bounding boxes (`getTextContent()`) for hover highlights and inline editing (text, font size, font family, color).
- **Backend Rate Limiter**: Enforces a 3 edit operations per day policy backed by an isolated SQLite table (`Services/storage/rate_limits.db`) returning HTTP 429 when exceeded.

### 2. Image Adjuster & Manipulator Tool (`/tools/image-manipulator`)
- Full client-side image manipulation suite:
  - **Brightness**, **Contrast**, and **Saturation** controls
  - **Blur**, **Grayscale**, **Sepia**, and **Invert** filter effects
  - **Rotate 90°**, **Flip Horizontal**, and **Flip Vertical** options
  - **PNG / JPG / WebP** export choices.

### 3. Sidebar Exclusive Available Tools Section (`NavigationDrawer.jsx`)
- Added a dedicated menu section highlighting exclusive features with daily usage badges:
  - **PDF Editor** (`3 Edits/Day`)
  - **AI Assistant** (`5 AI/Day`)
  - **Image Adjuster** (`Unlimited`)

### 4. Headless Render Deployment Fixes
- Replaced `opencv-python` with `opencv-python-headless` to eliminate missing GUI library crashes on headless Linux servers.
- Updated `render-build.sh` with User-Agent request headers, `curl`/`wget` fallbacks, and non-blocking download logic.
- Upgraded `fastapi>=0.109.0` for full Pydantic v2 compatibility.

---

## 📦 Build & Release Artifacts

| Parameter | Value |
|---|---|
| **Version** | `7.3.2` |
| **Version Code** | `732` |
| **Release Artifact** | `PaperKit-v7.3.2.apk` (~22.3 MB) |
| **Tag** | `v7.3.2` |

---

## 📥 Installation

1. Download **`PaperKit-v7.3.2.apk`** from the release assets.
2. Install the APK on your Android device (ensure "Install from Unknown Sources" is allowed).
3. Open PaperKit and enjoy the new PDF Editor and Image Manipulator tools!
