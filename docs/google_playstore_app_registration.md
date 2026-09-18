# MASKERV - Google Play Console App Registration & Store Listing Data Specification

This document provides complete, authoritative store registration details, application data, permissions declarations, privacy safety specs, and store listing metadata for publishing **MASKERV** (`com.maskerv.app`) on the **Google Play Store**.

---

## 1. Core Application Identity & Metadata

| Field | Value / Configuration |
| :--- | :--- |
| **App Title** | `MASKERV - AI Document & Workspace Studio` |
| **Short Description** | `All-in-One AI PDF Editor, Scanner, Academic Suite, Converter & Cryptographic Vault.` |
| **Package Name (`appId`)**| `com.maskerv.app` |
| **Default Language** | `English (United States) [en-US]` |
| **Supported Languages**| `English (en)`, `Spanish (es)`, `French (fr)`, `German (de)`, `Chinese (zh)`, `Japanese (ja)`, `Hindi (hi)` |
| **Version Name** | `1.0.5` |
| **Version Code** | `6` |
| **Target SDK / Min SDK**| Target: `Android 14 / 15` (API Level 34/35) \| Min SDK: `Android 8.0` (API Level 26) |
| **App Category** | `Productivity` / `Tools` (Secondary: `Education`) |
| **Tags / Keywords** | `PDF Editor`, `Document Scanner`, `OCR`, `PDF Converter`, `Academic AI`, `PDF Merge`, `Bates Stamping`, `Encrypted Share` |

---

## 2. Store Listing Copywriting & Descriptions

### Short Description (80 Characters Max)
> `Open-Source AI PDF Editor, Document Scanner, Converter & Academic Workspace.`

### Full Description (4,000 Characters Max)
```text
MASKERV is the ultimate cross-platform document, media, and academic intelligence workspace. Designed to address fragmentation, subscription barriers, and privacy concerns, MASKERV combines offline edge-computed processing with an advanced AI backend engine.

🚀 KEY FEATURES & TOOL DOMAINS (79 TOOLS INCLUDED):

📄 STRUCTURAL PDF & DOCUMENT TOOLS
• Merge, Split, Compress, Rotate, Watermark, N-Up Imposition, and Saddle-Stitch Booklet creation.
• In-place text editing: Modify text strings, fonts, and baseline alignment directly inside PDFs without flattening.
• Format Converter: Convert seamlessly between PDF, Word (DOCX), Excel (XLSX), PowerPoint (PPTX), Images, HTML, and Text.

📷 COMPUTER VISION DOCUMENT SCANNER
• Real-time OpenCV contour detection with perspective un-warping.
• Specialized adaptive filters for Documents, Receipts, ID Cards (CLAHE LAB optimization), and Books (Shadow removal).

🎓 ACADEMIC & AI RESEARCH SUITE
• Dual AI Engine powered by Groq (LLaMA 3.2 Vision) and Google Gemini 3.6 Flash.
• Perform Multimodal OCR, Literature Reviews, Research Gap Finding, Citation Extraction & Formatting (APA, MLA, IEEE, BibTeX), Study Note & Quiz Generation, and Audio Podcast creation.

🔒 CRYPTOGRAPHIC VAULT & EPHEMERAL SHARING
• AES-256-GCM encrypted 10-minute self-destructing file sharing with PBKDF2-HMAC-SHA256 key derivation.
• Zero-plaintext server logging, brute-force protection, and biometric app lock.

🎙️ MULTIMEDIA & ARCHIVE STUDIO
• Audio/video transcoding, CRF video compression, frame extraction, timeline editing, and archive extraction (ZIP, 7Z, TAR, GZ, RAR).

Privacy First: MASKERV includes client-side edge processing for lightweight PDF operations, keeping sensitive documents on your device.
```

---

## 3. Android Permissions Declaration & Justifications

These permission declarations map directly to `AndroidManifest.xml` (`maskerv_flutter/android/app/src/main/AndroidManifest.xml` and `maskerv-web/android/app/src/main/AndroidManifest.xml`):

| Android Permission | Google Play Console Justification | Data Safety Category |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | Required to communicate with the FastAPI backend service for AI research processing, online conversions, and cloud storage. | App Functionality |
| `android.permission.ACCESS_NETWORK_STATE` | Used to check connectivity status and route lightweight PDF tasks to client-side edge WebAssembly/Syncfusion processing when offline. | App Functionality |
| `android.permission.READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` | Required for users to pick images for scanning/conversion, videos for editing/frame extraction, and audio files. | Files & Docs, Photos & Videos |
| `android.permission.READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (Max SDK 32) | Required on older Android versions to load source files and export generated PDFs, DOCX, XLSX, and ZIP archives. | Files & Docs |
| `android.permission.CAMERA` | Required for the document scanner, camera OCR capture, and live QR/Barcode scanner features. | Photos & Videos (Scanner) |
| `android.permission.USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional permission used solely for Biometric App Lock screen security. | Authentication |

---

## 4. Play Console Data Safety & App Access Answers

### App Access Declaration
- **Does your app require credentials to access features?** -> **No, all functionality is available without restrictions**.
- **Architecture Note**: There are no user sign-up, user login, or user accounts. Anonymous UUIDv4 User IDs are generated locally (`StorageService.getAnonymousUserId()`) and passed to backend endpoints solely for **process isolation and concurrency protection** to prevent concurrent task collisions across different user devices.

### Data Collection & Sharing
- **Does your app collect or share any of the required user data types?** -> **No**. Personal user data is zero by default; document files and media are processed transiently for requested features and never shared with third parties.
- **Is all user data encrypted in transit?** -> **Yes**, mandatory HTTPS/TLS 1.3 protocol.
- **Account Deletion**: **Not Applicable (No User Accounts Exist)**. Users can reset their local session ID (`resetAnonymousIdentity()`) or clear local cache.

### Data Types Detail
| Category | Collected? | Shared? | Purpose | Processing / Retention |
| :--- | :---: | :---: | :--- | :--- |
| **Personal Information** | No | No | N/A | None (No User Accounts) |
| **Files & Documents** | Optional | No | App Functionality (User uploads for PDF/AI operations) | Ephemeral (Auto-purged in 15 mins) |
| **Photos & Videos** | Optional | No | App Functionality (Camera scan / Video editing) | Local / Processed on Demand |
| **App Info & Performance** | No | No | N/A | None |
| **Device Identifiers** | No | No | N/A | Anonymous Session UUID (Process Isolation) |

---

## 5. Privacy Policy Artifacts

- **Markdown Specification**: [`o:\PaperKit\docs\privacy_policy.md`](file:///o:/PaperKit/docs/privacy_policy.md)
- **Hosted HTML Privacy Policy**: [`o:\PaperKit\docs\privacy_policy.html`](file:///o:/PaperKit/docs/privacy_policy.html)
- **Play Console Public Privacy URL**: `https://maskerv-web.onrender.com/privacy`

---

## 6. Google Play Store Release APK Artifact Details

- **Release Tag**: `maskerV`
- **Release URL**: [https://github.com/HARSHINIK096/PaperKit/releases/tag/maskerV](https://github.com/HARSHINIK096/PaperKit/releases/tag/maskerV)
- **APK Path**: [`o:\PaperKit\maskerv_flutter\build\app\outputs\flutter-apk\app-release.apk`](file:///o:/PaperKit/maskerv_flutter/build\app\outputs\flutter-apk\app-release.apk)
- **Build Type**: `Android Release APK (ARM64-v8a, armeabi-v7a, x86_64)`

