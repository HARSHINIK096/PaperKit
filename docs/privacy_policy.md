# Privacy Policy for MASKERV

**Last Updated:** September 18, 2026  
**Effective Date:** September 18, 2026  
**Application Name:** MASKERV - AI Document & Workspace Studio (`com.maskerv.app`)  
**Developer / Contact Email:** `support@maskerv.app` / `harshinik096@gmail.com`  

---

## 1. Introduction & Overview

Welcome to **MASKERV** ("we," "our," or "us"). We are committed to protecting your privacy and ensuring complete transparency regarding how your data is handled when you use our mobile application (**MASKERV - AI Document & Workspace Studio**, package `com.maskerv.app`), web platform, and related backend APIs (collectively, the "Application").

MASKERV is engineered with a **zero-account, edge-first architecture**. The application is 100% functional out of the box **without requiring account registration, user sign-up, user login, or any personal data input**.

By using MASKERV, you agree to the processing of information in accordance with this Privacy Policy.

---

## 2. Architecture & Data Handling

### A. Zero User Accounts / Zero Personal Data Collection
- **No Registration, Sign-Up, or Login:** MASKERV contains no user registration forms, sign-up flows, login screens, or user credential stores.
- **No Personal Data Collected:** We do not collect or request names, email addresses, phone numbers, home addresses, or passwords.
- **No Advertising Trackers or Mobile Identifiers:** We do not collect or harvest Advertising IDs (`AAID`), Android IDs, hardware serial numbers, or persistent device fingerprints.
- **No Telemetry Harvesting:** We do not track or sell clickstreams, external browsing histories, or background behavioral analytics.

### B. Anonymous Session IDs & Process Separation
To ensure seamless multi-user cloud processing:
- **Anonymous Device Session ID:** When the application runs, the client locally generates an anonymous RFC4122 v4 UUID (`StorageService.getAnonymousUserId()`).
- **Technical Purpose of Anonymous Session ID:** This ID is transmitted in backend headers solely for **process isolation and concurrency protection**—ensuring that if multiple users initiate document processing tasks at the same time, each user's jobs, temporary files, and rate limits remain strictly isolated without cross-user data collisions or file mismatches.
- **Local Scope:** The profile and history screens in the Application display local device processing logs tied exclusively to that device's anonymous session ID.

### C. Documents, Media & Files Handling
- **Client-Side Edge Processing:** Standard PDF tools (merging, splitting, rotating, watermarking, N-Up imposition, WebAssembly utilities) execute **100% locally on your device**. Files involved in local operations never touch any remote server.
- **Transient AI & Conversion Processing:** For features requiring cloud AI (such as Multimodal Vision OCR, PDF Summarization, Research Paper Analysis, Quiz Generation, and Media Transcoding), your selected file or extracted text is transmitted securely via HTTPS/TLS to our backend servers (`Services`).
- **15-Minute Ephemeral Server Auto-Purge:** File processing on our backend runs in isolated ephemeral server sandboxes. All temporary uploaded files and output files are **automatically and permanently purged from our servers after 15 minutes** (`Services/main.py`).
- **10-Minute Encrypted Temporary Shares:** Files shared ephemerally via the Secure Share feature are encrypted end-to-end using **AES-256-GCM encryption** with zero server logging and self-destruct automatically after 10 minutes (or upon reaching 5 invalid password attempts).

---

## 3. How We Use Information

We process the minimal data required strictly for:
1. **App Functionality:** To execute user-requested document processing, optical character recognition (OCR), AI document analysis, audio/video transcoding, and format conversions.
2. **Process Isolation:** To segregate concurrent processing jobs and prevent task collisions between different client devices.
3. **Security & Rate Limiting:** To enforce fair-use rate limits and protect our server infrastructure against automated abuse.

We **NEVER** sell, rent, monetize, or trade your personal data, files, or document contents to advertisers, data brokers, or third parties.

---

## 4. Third-Party Service Providers & Cloud Engines

To power advanced multimodal AI features, MASKERV communicates securely with backend API service providers under strict data privacy standards:

| Service Provider | Purpose | Data Transmitted | Retention & Usage Policy |
| :--- | :--- | :--- | :--- |
| **Groq Cloud API** | LLaMA 3.3 Text & Vision AI Processing | User-submitted document text / image excerpts | Processed transiently in memory; zero training data retention. |
| **Google Gemini API** | Gemini 3.6 Multimodal AI Engine | User-submitted document text / image excerpts | Processed transiently under Google Cloud enterprise privacy standards; zero data training. |

*Note: All API keys and cloud credentials reside strictly on our backend servers and are never exposed to the client application.*

---

## 5. Device Permissions & Justifications

MASKERV requests only the minimum necessary device permissions required to perform user-initiated features. You can grant or revoke these permissions at any time via your device settings:

| Android Permission | Feature / Purpose | Sensitive Category |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | Required to communicate with FastAPI backend for cloud AI, conversions, and secure shares. | Normal |
| `android.permission.ACCESS_NETWORK_STATE` | Checks network availability to seamlessly switch to client-side offline WASM engines when offline. | Normal |
| `android.permission.READ_MEDIA_IMAGES` | Allows you to select photos/images for document scanning, OCR, image conversion, and editing. | Dangerous |
| `android.permission.READ_MEDIA_VIDEO` | Allows you to select video files for compression, frame extraction, and media editing. | Dangerous |
| `android.permission.READ_MEDIA_AUDIO` | Allows you to select audio files for format conversion and voice podcast generation. | Dangerous |
| `android.permission.READ_EXTERNAL_STORAGE` | (Android 12 and below) Legacy permission to pick source documents for processing. | Dangerous |
| `android.permission.WRITE_EXTERNAL_STORAGE` | (Android 12 and below) Legacy permission to save converted PDFs, DOCX, and archives to device storage. | Dangerous |
| `android.permission.CAMERA` | Enables live camera document scanning, camera OCR capture, and QR/Barcode scanning. | Dangerous |
| `android.permission.USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional permission used exclusively for local Biometric App Lock screen protection. | Normal |

---

## 6. Data Security & Encryption

We enforce multi-layered cryptographic security measures:
- **Encryption in Transit:** All network communication between the client and our backend APIs uses mandatory **TLS 1.3 / HTTPS encryption**.
- **Encryption at Rest:** Ephemeral shared files utilize **AES-256-GCM** encryption with keys derived via PBKDF2-HMAC-SHA256.
- **Zero Plaintext Logging:** File contents, OCR transcripts, and security tokens are never recorded in unencrypted server log files.

---

## 7. Data Retention & User Control

### A. Data Retention
- **Local Files:** Documents processed locally remain strictly on your device.
- **Server Files:** Guest files are automatically purged after 15 minutes. Ephemeral shared files expire after 10 minutes.
- **Account Profiles:** Not applicable — no user accounts exist.

### B. User Control & Data Clearing
Because no user accounts exist, there are no user account deletion procedures required. Users have full control over local data:
- **Reset Anonymous Session Identity:** Users can reset their local anonymous ID (`StorageService.resetAnonymousIdentity()`) at any time.
- **In-App Clear History & Cache:** Open **Settings (`/profile`)** and tap **"Clear Storage & History Data"** to immediately purge local document records, processing logs, and temporary cache.

---

## 8. Children's Privacy

MASKERV is designed for general academic, professional, and personal productivity use by individuals aged **13 and older**. We do not knowingly collect or solicit personal information from children under the age of 13.

---

## 9. Changes to This Privacy Policy

We may update our Privacy Policy periodically to reflect changes in functionality or legal compliance. Modifications will be posted on this page with an updated "Last Updated" date.

---

## 10. Contact Us

If you have any questions or privacy inquiries regarding MASKERV's data practices, contact us at:

- **Email:** `support@maskerv.app` / `harshinik096@gmail.com`
- **GitHub Repository:** [https://github.com/HARSHINIK096/PaperKit](https://github.com/HARSHINIK096/PaperKit)  
- **Web Portal:** [https://maskerv-web.onrender.com](https://maskerv-web.onrender.com)
