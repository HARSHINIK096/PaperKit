import api, { fastGet } from './api';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';

export const DEFAULT_REGISTRY = [
  // PDF Management
  { toolId: 'merge-pdf', name: 'Merge PDF', category: 'PDF Tools', route: '/tools/merge', description: 'Combine multiple PDFs in custom order', availability: { available: true } },
  { toolId: 'split-pdf', name: 'Split PDF', category: 'PDF Tools', route: '/tools/split', description: 'Split PDF by ranges, every N pages, or single pages', availability: { available: true } },
  { toolId: 'extract-pages', name: 'Extract Pages', category: 'PDF Tools', route: '/tools/extract-pages', description: 'Select and extract specific pages', availability: { available: true } },
  { toolId: 'organize-pages', name: 'Organize Pages', category: 'PDF Tools', route: '/tools/organize-pages', description: 'Delete, reorder, duplicate & rotate pages', availability: { available: true } },
  { toolId: 'rotate-pdf', name: 'Rotate PDF', category: 'PDF Tools', route: '/tools/rotate', description: 'Rotate PDF pages permanently', availability: { available: true } },
  { toolId: 'compress-pdf', name: 'Compress PDF', category: 'PDF Tools', route: '/tools/compress', description: 'Reduce PDF file size with multi-level optimization', availability: { available: true } },
  { toolId: 'watermark', name: 'Watermark', category: 'PDF Tools', route: '/tools/watermark', description: 'Add confidential text/image watermarks', availability: { available: true } },
  { toolId: 'pdf-editor', name: 'PDF Editor', category: 'PDF Tools', route: '/tools/pdf-editor', description: 'In-place text editing and object/image replacement', availability: { available: true } },
  
  // Conversions
  { toolId: 'word-to-pdf', name: 'Word to PDF', category: 'Convert', route: '/tools/convert?from=word&to=pdf', description: 'Convert Word documents to PDF', availability: { available: true } },
  { toolId: 'pdf-to-word', name: 'PDF to Word', category: 'Convert', route: '/tools/convert?from=pdf&to=word', description: 'Convert PDF to editable Word document', availability: { available: true } },
  { toolId: 'pdf-to-excel', name: 'PDF to Excel', category: 'Convert', route: '/tools/convert?from=pdf&to=excel', description: 'Extract tables to Excel spreadsheet', availability: { available: true } },
  { toolId: 'excel-to-pdf', name: 'Excel to PDF', category: 'Convert', route: '/tools/convert?from=excel&to=pdf', description: 'Convert spreadsheets to PDF', availability: { available: true } },
  { toolId: 'pdf-to-ppt', name: 'PDF to PPT', category: 'Convert', route: '/tools/convert?from=pdf&to=ppt', description: 'Convert PDF pages to PowerPoint slides', availability: { available: true } },
  { toolId: 'ppt-to-pdf', name: 'PPT to PDF', category: 'Convert', route: '/tools/convert?from=ppt&to=pdf', description: 'Convert presentations to PDF', availability: { available: true } },
  { toolId: 'pdf-to-image', name: 'PDF to Image', category: 'Convert', route: '/tools/convert?from=pdf&to=image', description: 'Convert PDF pages to high-res images', availability: { available: true } },
  { toolId: 'image-to-pdf', name: 'Image to PDF', category: 'Convert', route: '/tools/convert?from=image&to=pdf', description: 'Convert JPG/PNG images to PDF', availability: { available: true } },
  
  // Image Tools
  { toolId: 'jpg-to-png', name: 'JPG to PNG', category: 'Image Tools', route: '/tools/image-converter?from=jpg&to=png', description: 'Convert JPG images to PNG format', availability: { available: true } },
  { toolId: 'png-to-jpg', name: 'PNG to JPG', category: 'Image Tools', route: '/tools/image-converter?from=png&to=jpg', description: 'Convert PNG images to JPG format', availability: { available: true } },
  { toolId: 'webp-to-jpg', name: 'WebP to JPG', category: 'Image Tools', route: '/tools/image-converter?from=webp&to=jpg', description: 'Convert WebP images to JPG format', availability: { available: true } },
  { toolId: 'webp-to-png', name: 'WebP to PNG', category: 'Image Tools', route: '/tools/image-converter?from=webp&to=png', description: 'Convert WebP images to PNG format', availability: { available: true } },
  { toolId: 'heic-to-jpg', name: 'HEIC to JPG', category: 'Image Tools', route: '/tools/image-converter?from=heic&to=jpg', description: 'Convert Apple HEIC photos to JPG', availability: { available: true } },
  { toolId: 'bmp-to-jpg', name: 'BMP to JPG', category: 'Image Tools', route: '/tools/image-converter?from=bmp&to=jpg', description: 'Convert Bitmap images to JPG', availability: { available: true } },
  { toolId: 'image-compressor', name: 'Image Compressor', category: 'Image Tools', route: '/tools/image-compressor', description: 'Compress images with multiple quality presets', availability: { available: true }, capabilities: ['compress', 'optimize', 'resize'] },  
  // AI Tools
  { toolId: 'ai-ocr', name: 'OCR Text Detection', category: 'AI Tools', route: '/ai/ocr', description: 'Extract text & layout from scanned PDFs and images', availability: { available: true } },
  { toolId: 'summarize-pdf', name: 'AI Summary', category: 'AI Tools', route: '/ai/summarize', description: 'Smart summary, key points, findings & action items', availability: { available: true } },
  { toolId: 'semantic-compare', name: 'Semantic Compare', category: 'AI Tools', route: '/ai/compare', description: 'Compare meaning & detect temporal/financial changes', availability: { available: true } },
  { toolId: 'similarity-matrix', name: 'Similarity Score', category: 'AI Tools', route: '/ai/similarity', description: 'Calculate document similarity % and duplicate detection', availability: { available: true } },
  { toolId: 'ask-pdf', name: 'AI Document Chat', category: 'AI Tools', route: '/ai/ask', description: 'Interactive Q&A and conversational research', availability: { available: true } },
  { toolId: 'semantic-search', name: 'Semantic Search', category: 'AI Tools', route: '/ai/search', description: 'Search document by intent and conceptual meaning', availability: { available: true } },
  { toolId: 'classify-pdf', name: 'Document Classification', category: 'AI Tools', route: '/ai/classify', description: 'Auto-identify document category and structure', availability: { available: true } },
  { toolId: 'extract-info', name: 'Information Extraction', category: 'AI Tools', route: '/ai/extract-info', description: 'Extract structured fields from invoices, resumes & papers', availability: { available: true } },
  { toolId: 'translate-pdf', name: 'AI Translation', category: 'AI Tools', route: '/ai/translate', description: 'Translate document into 15+ languages', availability: { available: true } },
  { toolId: 'writing-assistant', name: 'Writing Assistant', category: 'AI Tools', route: '/ai/writing-assist', description: 'Grammar, paraphrasing, simplifying & formal rewrite', availability: { available: true } },
  { toolId: 'quality-checker', name: 'Quality Checker', category: 'AI Tools', route: '/ai/quality-checker', description: 'Audit structure, citations, consistency & readability', availability: { available: true } },
  { toolId: 'ai-image-enhancer', name: 'AI Image Enhancer', category: 'AI Tools', route: '/ai/image-enhancer', description: 'Upscale and enhance image quality using AI', availability: { available: true }, capabilities: ['upscale', 'enhance', 'resolution'] },

  // Security & Privacy
  { toolId: 'protect-pdf', name: 'Protect PDF', category: 'Security', route: '/security/protect', description: 'Password protection and AES encryption', availability: { available: true } },
  { toolId: 'smart-redaction', name: 'Redact Data', category: 'Security', route: '/security/redact', description: 'Detect and blackout sensitive PII data', availability: { available: true } },
  { toolId: 'digital-sign', name: 'Digital Signature', category: 'Security', route: '/security/sign', description: 'Draw, upload or stamp digital signatures', availability: { available: true } },
  { toolId: 'metadata-manager', name: 'Metadata Manager', category: 'Security', route: '/security/metadata', description: 'View, edit or sanitize PDF metadata for privacy', availability: { available: true } },

  // Archive & Compression Tools (.ZIP, .RAR, .TAR, .GZ, .7Z, .BZ2)
  { toolId: 'extract-archive', name: 'Extract Archive (.ZIP, .RAR, .TAR, .GZ, .7Z, .BZ2)', category: 'Archive Tools', route: '/tools/archive?mode=extract', description: 'Extract and inspect files from ZIP, RAR, TAR, GZ, 7Z, and BZ2 archives', availability: { available: true }, capabilities: ['extract', 'inspect', 'decompress'] },
  { toolId: 'create-zip', name: 'Create ZIP Archive', category: 'Archive Tools', route: '/tools/archive?mode=create&format=zip', description: 'Pack and compress multiple files into a universal .ZIP archive', availability: { available: true }, capabilities: ['zip', 'compress', 'package'] },
  { toolId: 'create-tar', name: 'Create TAR / GZ Archive', category: 'Archive Tools', route: '/tools/archive?mode=create&format=tar', description: 'Create uncompressed TAR and compressed TAR.GZ packages', availability: { available: true }, capabilities: ['tar', 'gzip', 'package'] },
  { toolId: 'convert-archive', name: 'Convert Archive Format', category: 'Archive Tools', route: '/tools/archive?mode=extract', description: 'Convert RAR, 7Z, TAR, and BZ2 to universal ZIP archive', availability: { available: true }, capabilities: ['convert', 'zip'] },
  { toolId: 'archive-manager', name: 'Archive Studio', category: 'Archive Tools', route: '/tools/archive', description: 'Complete multi-format archive extraction and compression suite', availability: { available: true }, capabilities: ['archive', 'zip', 'tar', 'extract'] },

  // Video Tools
  { toolId: 'video-to-mp4', name: 'Convert to MP4', category: 'Video Tools', route: '/tools/video-converter?to=mp4', description: 'Convert video files to universal MP4 format', availability: { available: true } },
  { toolId: 'video-to-webm', name: 'Convert to WebM', category: 'Video Tools', route: '/tools/video-converter?to=webm', description: 'Convert videos to high-efficiency WebM', availability: { available: true } },
  { toolId: 'video-to-mov', name: 'Convert to MOV', category: 'Video Tools', route: '/tools/video-converter?to=mov', description: 'Convert videos to Apple QuickTime MOV', availability: { available: true } },
  { toolId: 'video-to-gif', name: 'Convert to GIF', category: 'Video Tools', route: '/tools/video-converter?to=gif', description: 'Convert video clips to animated GIF', availability: { available: true } },
  { toolId: 'vcompress-low', name: 'Video Compressor (Light)', category: 'Video Tools', route: '/tools/video-compressor?preset=low', description: 'Light video compression with maximum quality', availability: { available: true } },
  { toolId: 'vcompress-medium', name: 'Video Compressor (Balanced)', category: 'Video Tools', route: '/tools/video-compressor?preset=medium', description: 'Balanced video compression for sharing', availability: { available: true } },
  { toolId: 'vcompress-high', name: 'Video Compressor (Extreme)', category: 'Video Tools', route: '/tools/video-compressor?preset=high', description: 'Maximum file size reduction for videos', availability: { available: true } },

  // Audio Tools
  { toolId: 'audio-to-mp3', name: 'Convert to MP3', category: 'Audio Tools', route: '/tools/audio-converter?to=mp3', description: 'Convert audio tracks to standard MP3 format', availability: { available: true } },
  { toolId: 'audio-to-wav', name: 'Convert to WAV', category: 'Audio Tools', route: '/tools/audio-converter?to=wav', description: 'Convert audio to lossless uncompressed WAV', availability: { available: true } },
  { toolId: 'audio-to-ogg', name: 'Convert to OGG', category: 'Audio Tools', route: '/tools/audio-converter?to=ogg', description: 'Convert audio to web-optimized OGG Vorbis', availability: { available: true } },

  // Media Downloader
  { toolId: 'youtube-downloader', name: 'YouTube Video Downloader', category: 'Media Downloader', route: '/tools/media-downloader?type=youtube', description: 'Download YouTube videos as high-res MP4', availability: { available: true } },
  { toolId: 'spotify-downloader', name: 'Spotify Audio Downloader', category: 'Media Downloader', route: '/tools/media-downloader?type=spotify', description: 'Download Spotify tracks as high-bitrate MP3', availability: { available: true } },
];

let cachedRegistry = DEFAULT_REGISTRY;

export function getToolsRegistrySync() {
  try {
    const raw = localStorage.getItem('pk_tools_registry');
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
  } catch {
    // Ignore error
  }
  return cachedRegistry;
}

export async function getToolsRegistry() {
  // Always return local cached registry immediately for 0ms latency
  const current = getToolsRegistrySync();
  
  // Non-blocking background revalidation
  fastGet('/tools/registry')
    .then(res => {
      if (Array.isArray(res.data) && res.data.length > 0) {
        const mapped = res.data.map(t => ({
          ...t,
          availability: { available: true, ...(t.availability || {}) }
        }));
        cachedRegistry = mapped;
        try { localStorage.setItem('pk_tools_registry', JSON.stringify(mapped)); } catch { /* ignore storage error */ }
      }
    })
    .catch(() => {});

  return current;
}

export async function getProcessingHistory() {
  let localHistory = [];
  try {
    const raw = localStorage.getItem('pk_local_history');
    if (raw) localHistory = JSON.parse(raw);
  } catch {
    localHistory = [];
  }

  // Attempt fast revalidation from server
  try {
    const res = await fastGet('/tools/history');
    if (Array.isArray(res.data) && res.data.length > 0) {
      try { localStorage.setItem('pk_local_history', JSON.stringify(res.data)); } catch { /* ignore storage error */ }
      return res.data;
    }
  } catch (err) {
    console.debug('Backend history sync unavailable, using cached history:', err.message);
  }
  
  return localHistory;
}

export async function mergePDF(fileIds, options) {
  const res = await api.post('/tools/merge', { file_ids: fileIds, options });
  return res.data;
}

export async function splitPDF(fileId, options) {
  const res = await api.post('/tools/split', { file_id: fileId, ...options });
  return res.data;
}

export async function compressPDF(fileId, quality) {
  const res = await api.post('/tools/compress', { file_id: fileId, quality });
  return res.data;
}

export async function convertFile(fileId, fromFormat, toFormat, options = {}) {
  const res = await api.post('/tools/convert', {
    file_id: fileId,
    from_format: fromFormat,
    to_format: toFormat,
    ...options,
  });
  return res.data;
}

export async function estimateCompression(fileId, quality) {
  const res = await api.post('/tools/compress/estimate', { file_id: fileId, quality });
  return res.data; // { original_size, estimated_size, reduction_pct }
}

export async function rotatePDF(fileId, degrees, pages) {
  const res = await api.post('/tools/rotate', { file_id: fileId, degrees, pages });
  return res.data;
}

export async function addWatermark(fileId, options) {
  const res = await api.post('/tools/watermark', { file_id: fileId, ...options });
  return res.data;
}

export async function protectPDF(fileId, options) {
  const res = await api.post('/tools/protect', { file_id: fileId, ...options });
  return res.data;
}

export async function signPDF(fileId, signatures) {
  const res = await api.post('/tools/sign', { file_id: fileId, signatures });
  return res.data;
}

export async function getPDFMetadata(fileId) {
  const res = await api.get(`/tools/metadata/${fileId}`);
  return res.data;
}

export async function updatePDFMetadata(fileId, updates, wipeAll = false) {
  const res = await api.post('/tools/metadata', { file_id: fileId, updates, wipe_all: wipeAll });
  return res.data;
}

export async function redactPDF(fileId, terms) {
  const res = await api.post('/tools/redact', { file_id: fileId, terms });
  return res.data;
}

export async function convertHtmlToWord(htmlContent, filename = 'edited_document.docx') {
  const res = await api.post('/tools/html-to-word', {
    html_content: htmlContent,
    filename,
  });
  return res.data;
}



export async function organizePDF(fileId, pages, toolId = 'organize-pages') {
  const res = await api.post('/tools/organize', { file_id: fileId, pages, tool_id: toolId });
  return res.data;
}

export async function getEditorLimits() {
  return { remaining: 'Unlimited', limit: '∞', resets_at: 'Instant' };
}

/**
 * High-performance client-side in-place PDF editor using pdf-lib WASM/JS engine.
 * Redacts bounding boxes cleanly and overlays updated text and images locally.
 */
export async function applyPdfEditsLocal(fileBlobOrBuffer, editsPayload) {
  const arrayBuffer = fileBlobOrBuffer instanceof ArrayBuffer
    ? fileBlobOrBuffer
    : await fileBlobOrBuffer.arrayBuffer();

  const pdfDoc = await PDFDocument.load(arrayBuffer, { ignoreEncryption: true });
  const pagesPayload = Array.isArray(editsPayload) ? editsPayload : [editsPayload];

  const fontCache = {};
  async function getFont(fontName = 'Helvetica', isBold = false, isItalic = false) {
    const fn = (fontName || '').toLowerCase();
    let stdFont = StandardFonts.Helvetica;
    if (fn.includes('times') || fn.includes('serif') || fn.includes('roman')) {
      if (isBold && isItalic) stdFont = StandardFonts.TimesRomanBoldItalic;
      else if (isBold) stdFont = StandardFonts.TimesRomanBold;
      else if (isItalic) stdFont = StandardFonts.TimesRomanItalic;
      else stdFont = StandardFonts.TimesRoman;
    } else if (fn.includes('courier') || fn.includes('mono')) {
      if (isBold && isItalic) stdFont = StandardFonts.CourierBoldOblique;
      else if (isBold) stdFont = StandardFonts.CourierBold;
      else if (isItalic) stdFont = StandardFonts.CourierOblique;
      else stdFont = StandardFonts.Courier;
    } else {
      if (isBold && isItalic) stdFont = StandardFonts.HelveticaBoldOblique;
      else if (isBold) stdFont = StandardFonts.HelveticaBold;
      else if (isItalic) stdFont = StandardFonts.HelveticaOblique;
      else stdFont = StandardFonts.Helvetica;
    }

    if (!fontCache[stdFont]) {
      fontCache[stdFont] = await pdfDoc.embedFont(stdFont);
    }
    return fontCache[stdFont];
  }

  const totalPages = pdfDoc.getPageCount();

  for (const pageEntry of pagesPayload) {
    if (!pageEntry) continue;
    const rawPg = pageEntry.page_number || pageEntry.page || 1;
    let pgIdx = parseInt(rawPg, 10);
    if (pgIdx >= 1 && pgIdx <= totalPages) {
      pgIdx = pgIdx - 1;
    } else if (pgIdx < 0 || pgIdx >= totalPages) {
      pgIdx = 0;
    }

    const page = pdfDoc.getPage(pgIdx);
    const { width: _pw, height } = page.getSize();
    const edits = pageEntry.edits || [];

    for (const edit of edits) {
      if (!edit || !edit.bbox || edit.bbox.length < 4) continue;
      const [x0, y0, x1, y1] = edit.bbox.map(Number);
      const rectWidth = Math.max(1, x1 - x0);
      const rectHeight = Math.max(1, y1 - y0);

      // pdf-lib Y origin is at bottom-left:
      const rectX = x0;
      const rectY = height - y1;

      if (edit.type === 'text') {
        const newText = edit.new_text !== undefined ? edit.new_text : (edit.text || '');
        const fontSize = parseFloat(edit.font_size) || 12;
        const isBold = Boolean(edit.is_bold);
        const isItalic = Boolean(edit.is_italic);
        const font = await getFont(edit.font_name || edit.raw_font_name, isBold, isItalic);

        // 1. Redact original bounding box with white background
        page.drawRectangle({
          x: rectX - 1,
          y: rectY - 1,
          width: rectWidth + 2,
          height: rectHeight + 2,
          color: rgb(1, 1, 1),
        });

        // 2. Draw new replacement text
        if (newText) {
          let [r, g, b] = [0, 0, 0];
          if (Array.isArray(edit.color) && edit.color.length === 3) {
            r = edit.color[0] > 1 ? edit.color[0] / 255 : edit.color[0];
            g = edit.color[1] > 1 ? edit.color[1] / 255 : edit.color[1];
            b = edit.color[2] > 1 ? edit.color[2] / 255 : edit.color[2];
          }

          const textY = rectY + Math.max(1, (rectHeight - fontSize) * 0.5 + 2);

          page.drawText(newText, {
            x: rectX,
            y: textY,
            size: fontSize,
            font,
            color: rgb(r, g, b),
          });
        }
      } else if (edit.type === 'image' && edit.new_image_base64) {
        let b64 = edit.new_image_base64;
        const isPng = b64.includes('image/png');
        if (b64.includes(',')) b64 = b64.split(',')[1];
        const binaryStr = atob(b64);
        const bytes = new Uint8Array(binaryStr.length);
        for (let i = 0; i < binaryStr.length; i++) {
          bytes[i] = binaryStr.charCodeAt(i);
        }
        const img = isPng ? await pdfDoc.embedPng(bytes) : await pdfDoc.embedJpg(bytes);
        page.drawImage(img, {
          x: rectX,
          y: rectY,
          width: rectWidth,
          height: rectHeight,
        });
      }
    }
  }

  const modifiedBytes = await pdfDoc.save();
  return { data: modifiedBytes, status: 200 };
}

export async function applyPdfEdits(fileOrFileId, editsPayload) {
  // Directly execute via client-side PDF-Lib engine for 0ms latency, offline reliability & zero server 404s
  if (fileOrFileId instanceof File || fileOrFileId instanceof Blob || fileOrFileId instanceof ArrayBuffer) {
    return await applyPdfEditsLocal(fileOrFileId, editsPayload);
  }

  // Fallback if only a remote file_id was provided
  const formData = new FormData();
  formData.append('file_id', fileOrFileId);
  formData.append('payload', JSON.stringify(editsPayload));

  const res = await api.post('/editor/edit', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    responseType: 'blob',
    timeout: 15000,
  });
  return res;
}



