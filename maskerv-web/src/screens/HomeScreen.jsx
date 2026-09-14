import { useState, useContext, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, Sparkles, Eye } from 'lucide-react';
import ToolCategory from '../components/ui/ToolCategory';
import FilePreviewModal from '../components/ui/FilePreviewModal';
import { useAuth } from '../hooks/useAuth';
import { SearchContext } from '../components/layout/AppShell';
import { QUICK_TOOLS, PDF_TOOLS, AI_TOOLS, SECURITY_TOOLS, CONVERT_TOOLS, ARCHIVE_TOOLS, IMAGE_FORMAT_TOOLS, IMAGE_COMPRESS_TOOLS, MEDIA_DOWNLOADER_TOOLS, VIDEO_FORMAT_TOOLS, VIDEO_COMPRESS_TOOLS, AUDIO_FORMAT_TOOLS } from '../config/tools-config';
import { getStorageUsage } from '../services/jobs';
import './HomeScreen.css';

export default function HomeScreen() {
  const navigate = useNavigate();
  const fileDropInputRef = useRef(null);
  const { user } = useAuth();
  const { query } = useContext(SearchContext);
  const [droppedFile, setDroppedFile] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [storageData, setStorageData] = useState(null);

  // File Preview State
  const [previewModalOpen, setPreviewModalOpen] = useState(false);
  const [previewTarget, setPreviewTarget] = useState(null);

  useEffect(() => {
    async function loadStorageStats() {
      try {
        const storageStats = await getStorageUsage().catch(() => null);
        if (storageStats) setStorageData(storageStats);
      } catch (err) {
        console.error('Failed to load storage stats:', err);
      }
    }
    loadStorageStats();
  }, []);

  function handleFileDrop(e) {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer?.files?.[0] || e.target?.files?.[0];
    if (file) {
      setDroppedFile(file);
    }
  }



  function handlePreviewDropped() {
    if (!droppedFile) return;
    setPreviewTarget({
      rawFile: droppedFile,
      name: droppedFile.name,
      size: droppedFile.size,
      mimeType: droppedFile.type,
    });
    setPreviewModalOpen(true);
  }

  const filteredQuickTools = QUICK_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredAITools = AI_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredPDFTools = PDF_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredSecurityTools = SECURITY_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredConvertTools = CONVERT_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredImageFormatTools = IMAGE_FORMAT_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredImageCompressTools = IMAGE_COMPRESS_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredMediaDownloaderTools = MEDIA_DOWNLOADER_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredVideoFormatTools = VIDEO_FORMAT_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredVideoCompressTools = VIDEO_COMPRESS_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredArchiveTools = ARCHIVE_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );
  const filteredAudioFormatTools = AUDIO_FORMAT_TOOLS.filter(t =>
    t.label.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="home-screen">
      <header className="home-screen__header">
        <h1 className="home-screen__greeting">
          {user?.name && user.name !== 'Guest User' ? `Welcome, ${user.name}` : 'MASKERV Intelligent PDF Platform'}
        </h1>
        <p className="home-screen__subtitle">Process, summarize, compare, and protect your documents with zero friction.</p>
      </header>

      {/* ⭐ Smart Document Dropzone & Fast Recommendation Engine */}
      <div
        className="home-screen__dropzone"
        onDragOver={e => { e.preventDefault(); setIsDragging(true); }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={handleFileDrop}
        style={{
          background: isDragging ? 'var(--color-primary-soft)' : 'var(--color-surface)',
          border: isDragging ? '2px dashed var(--color-primary)' : '1px dashed var(--color-divider)',
        }}
      >
        <input
          ref={fileDropInputRef}
          type="file"
          accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,image/*,.zip,.rar,.tar,.gz,.7z,.bz2,.tgz"
          style={{ display: 'none' }}
          onChange={handleFileDrop}
          id="home-dropzone-input"
        />

        {!droppedFile ? (
          <div
            onClick={() => fileDropInputRef.current?.click()}
            style={{ display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer', minWidth: 0 }}
          >
            <div style={{ width: 44, height: 44, minWidth: 44, borderRadius: 12, background: 'var(--color-primary-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Sparkles size={22} color="var(--color-primary)" />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 'var(--font-size-sm)', fontWeight: 700, color: 'var(--color-text-primary)' }}>
                Drop any document, image, or archive here
              </div>
              <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-secondary)', marginTop: '2px' }}>
                Auto-detects files, PDFs &amp; archives (.ZIP, .RAR, .TAR, .GZ, .7Z, .BZ2)
              </div>
            </div>
          </div>
        ) : (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px', gap: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, flex: 1 }}>
                <FileText size={18} color="var(--color-primary)" style={{ flexShrink: 0 }} />
                <span className="truncate" style={{ fontSize: '13px', fontWeight: 700 }}>{droppedFile.name}</span>
                <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', flexShrink: 0 }}>({(droppedFile.size / 1024).toFixed(1)} KB)</span>
              </div>
              <button
                type="button"
                onClick={() => setDroppedFile(null)}
                style={{ background: 'none', border: 'none', fontSize: '12px', color: '#EF4444', fontWeight: 600, cursor: 'pointer', flexShrink: 0 }}
              >
                Clear
              </button>
            </div>

            <div style={{ fontSize: '11px', fontWeight: 700, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '6px' }}>
              Recommended 1-Click Operations:
            </div>

            <div className="home-screen__dropzone-grid">
              <button
                type="button"
                onClick={handlePreviewDropped}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(37, 99, 235, 0.1)', border: '1px solid rgba(37, 99, 235, 0.25)', color: '#2563EB' }}
              >
                <Eye size={13} style={{ flexShrink: 0 }} /> <span className="truncate">Quick Preview</span>
              </button>
              <button
                type="button"
                onClick={() => navigate('/tools/archive', { state: { file: droppedFile } })}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(234, 88, 12, 0.08)', border: '1px solid rgba(234, 88, 12, 0.25)', color: '#EA580C' }}
              >
                <span className="truncate">📦 Extract / Archive</span>
              </button>
              <button
                type="button"
                onClick={() => navigate('/ai/summarize', { state: { file: droppedFile } })}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(124, 58, 237, 0.08)', border: '1px solid rgba(124, 58, 237, 0.2)', color: '#7C3AED' }}
              >
                <span className="truncate">✨ AI Summary</span>
              </button>
              <button
                type="button"
                onClick={() => navigate('/tools/compress', { state: { file: droppedFile } })}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(234, 88, 12, 0.08)', border: '1px solid rgba(234, 88, 12, 0.2)', color: '#EA580C' }}
              >
                <span className="truncate">🗜️ Compress</span>
              </button>
              <button
                type="button"
                onClick={() => navigate('/ai/ocr', { state: { file: droppedFile } })}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(37, 99, 235, 0.08)', border: '1px solid rgba(37, 99, 235, 0.2)', color: '#2563EB' }}
              >
                <span className="truncate">🔍 OCR Text</span>
              </button>
              <button
                type="button"
                onClick={() => navigate('/security/protect', { state: { file: droppedFile } })}
                className="home-screen__dropzone-btn"
                style={{ background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#EF4444' }}
              >
                <span className="truncate">🔒 Password Lock</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Storage Summary widget */}
      {storageData && (
        <div className="home-screen__storage-summary" onClick={() => navigate('/storage')} style={{ cursor: 'pointer', background: 'var(--color-surface)', borderRadius: 'var(--radius-xl)', padding: 'var(--space-3) var(--space-4)', border: '1px solid var(--color-divider)', marginBottom: 'var(--space-4)', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-size-sm)' }}>
            <span style={{ color: 'var(--color-text-secondary)' }}>MASKERV Storage Usage: <strong>{storageData.totalMB} MB</strong> used</span>
            <span style={{ color: 'var(--color-text-muted)', fontWeight: 500 }}>{storageData.fileCount} Files</span>
          </div>
          <div style={{ height: '6px', background: 'var(--color-divider)', borderRadius: '3px', overflow: 'hidden' }}>
            <div style={{ height: '100%', background: 'var(--color-primary)', width: `${Math.min(100, (storageData.totalBytes / (500 * 1024 * 1024)) * 100)}%` }} />
          </div>
        </div>
      )}

      {/* ⭐ Quick Launch Grid */}
      {filteredQuickTools.length > 0 && (
        <section className="home-screen__section" aria-label="Quick Launch">
          <ToolCategory
            title="Featured Tools"
            tools={filteredQuickTools}
            showViewAll
            onViewAll={() => navigate('/tools')}
          />
        </section>
      )}

      {/* ⭐ AI Document Intelligence */}
      {filteredAITools.length > 0 && (
        <section className="home-screen__section" aria-label="AI Document Intelligence">
          <ToolCategory
            title="AI Document Intelligence"
            tools={filteredAITools}
            showViewAll
            onViewAll={() => navigate('/category/ai')}
          />
        </section>
      )}

      {/* ⭐ PDF Processing & Page Manager */}
      {filteredPDFTools.length > 0 && (
        <section className="home-screen__section" aria-label="PDF Processing & Pages">
          <ToolCategory
            title="PDF Processing &amp; Pages"
            tools={filteredPDFTools}
            showViewAll
            onViewAll={() => navigate('/category/pdf')}
          />
        </section>
      )}

      {/* ⭐ PDF Security & Privacy */}
      {filteredSecurityTools.length > 0 && (
        <section className="home-screen__section" aria-label="Security and Privacy">
          <ToolCategory
            title="Security &amp; Privacy"
            tools={filteredSecurityTools}
            showViewAll
            onViewAll={() => navigate('/category/security')}
          />
        </section>
      )}

      {/* ⭐ Conversions */}
      {filteredConvertTools.length > 0 && (
        <section className="home-screen__section" aria-label="Convert Documents">
          <ToolCategory
            title="Conversions"
            tools={filteredConvertTools}
            showViewAll
            onViewAll={() => navigate('/category/convert')}
          />
        </section>
      )}

      {/* ⭐ Image Format Converter */}
      {filteredImageFormatTools.length > 0 && (
        <section className="home-screen__section" aria-label="Image Format Converter">
          <ToolCategory
            title="Image Format Converter"
            tools={filteredImageFormatTools}
            showViewAll
            onViewAll={() => navigate('/category/image')}
          />
        </section>
      )}

      {/* ⭐ Image Compressor */}
      {filteredImageCompressTools.length > 0 && (
        <section className="home-screen__section" aria-label="Image Compressor">
          <ToolCategory
            title="Image Compressor ⭐"
            tools={filteredImageCompressTools}
            showViewAll
            onViewAll={() => navigate('/category/image')}
          />
        </section>
      )}

      {/* ⭐ Media Downloader */}
      {filteredMediaDownloaderTools.length > 0 && (
        <section className="home-screen__section" aria-label="Media Downloader">
          <ToolCategory
            title="Media Downloader (YouTube &amp; Spotify)"
            tools={filteredMediaDownloaderTools}
            showViewAll
            onViewAll={() => navigate('/category/downloader')}
          />
        </section>
      )}

      {/* ⭐ Video Format Converter */}
      {filteredVideoFormatTools.length > 0 && (
        <section className="home-screen__section" aria-label="Video Format Converter">
          <ToolCategory
            title="Video Format Converter"
            tools={filteredVideoFormatTools}
            showViewAll
            onViewAll={() => navigate('/category/video')}
          />
        </section>
      )}

      {/* ⭐ Video Compressor */}
      {filteredVideoCompressTools.length > 0 && (
        <section className="home-screen__section" aria-label="Video Compressor">
          <ToolCategory
            title="Video Compressor"
            tools={filteredVideoCompressTools}
            showViewAll
            onViewAll={() => navigate('/category/video')}
          />
        </section>
      )}

      {/* ⭐ Archive & Compression Tools */}
      {filteredArchiveTools.length > 0 && (
        <section className="home-screen__section" aria-label="Archive and Compression Tools">
          <ToolCategory
            title="Archive &amp; Compression (.ZIP, .RAR, .TAR, .GZ, .7Z, .BZ2)"
            tools={filteredArchiveTools}
            showViewAll
            onViewAll={() => navigate('/category/archive')}
          />
        </section>
      )}

      {/* ⭐ Audio Format Converter */}
      {filteredAudioFormatTools.length > 0 && (
        <section className="home-screen__section" aria-label="Audio Format Converter">
          <ToolCategory
            title="Audio Format Converter"
            tools={filteredAudioFormatTools}
            showViewAll
            onViewAll={() => navigate('/category/audio')}
          />
        </section>
      )}

      <FilePreviewModal
        isOpen={previewModalOpen}
        onClose={() => setPreviewModalOpen(false)}
        fileUrl={previewTarget?.url}
        fileName={previewTarget?.name}
        fileSize={previewTarget?.size}
        mimeType={previewTarget?.mimeType}
        fileId={previewTarget?.fileId}
        rawFile={previewTarget?.rawFile}
      />
    </div>
  );
}
