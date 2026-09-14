import { useState, useEffect, useRef, useCallback } from 'react';
import { 
  FileUp, Download, ChevronLeft, ChevronRight, 
  CheckCircle2, ShieldCheck, Sparkles, X,
  Palette, Minus, Plus
} from 'lucide-react';
import { applyPdfEdits } from '../../services/tools';
import { triggerHaptic, downloadAndOpenFile, showNativeToast } from '../../services/native';
import './PDFEditorScreen.css';

export default function PDFEditorScreen() {
  const [file, setFile] = useState(null);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [scale, setScale] = useState(() => {
    if (typeof window !== 'undefined' && window.innerWidth < 640) {
      return Math.min(0.68, Math.max(0.43, ((window.innerWidth - 32) / 595) * 0.9));
    }
    return 0.585;
  });
  const [textSpans, setTextSpans] = useState([]);
  const [pageViewport, setPageViewport] = useState(null);

  // Responsive scale listener for mobile devices & orientation changes
  useEffect(() => {
    function handleResize() {
      if (window.innerWidth < 640) {
        setScale(Math.min(0.68, Math.max(0.43, ((window.innerWidth - 32) / 595) * 0.9)));
      } else {
        setScale(0.585);
      }
    }
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Active edits per page: { [pageNum]: [ { id, type, bbox, new_text, font_name, font_size, color, new_image_base64 } ] }
  const [pageEdits, setPageEdits] = useState({});

  // Active text span being edited inline
  const [activeSpan, setActiveSpan] = useState(null);
  const [editText, setEditText] = useState('');
  const [editFontSize, setEditFontSize] = useState(12);
  const [editColor, setEditColor] = useState('#000000');
  const [editFontName, setEditFontName] = useState('Helvetica');
  const [editIsBold, setEditIsBold] = useState(false);
  const [editIsItalic, setEditIsItalic] = useState(false);

  const [_loading, setLoading] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');

  // Preview pinch zoom state (visual viewport zooming without document size change)
  const [previewZoom, setPreviewZoom] = useState(1);
  const [isPinching, setIsPinching] = useState(false);
  const touchStateRef = useRef({ initialDist: 0, initialZoom: 1 });

  const canvasRef = useRef(null);
  const viewportRef = useRef(null);
  const fileInputRef = useRef(null);

  // Reset visual zoom when changing page
  useEffect(() => {
    setPreviewZoom(1);
  }, [currentPage]);

  // Trackpad pinch-to-zoom & Ctrl+Wheel zoom listener on preview viewport
  useEffect(() => {
    const vp = viewportRef.current;
    if (!vp) return;

    const handleWheel = (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        const delta = -e.deltaY * 0.005;
        setPreviewZoom(prev => Math.min(3.5, Math.max(0.5, prev + delta)));
      }
    };

    vp.addEventListener('wheel', handleWheel, { passive: false });
    return () => vp.removeEventListener('wheel', handleWheel);
  }, [file]);

  // Touch screen 2-finger pinch zoom
  const handleTouchStart = (e) => {
    if (e.touches.length === 2) {
      const t1 = e.touches[0];
      const t2 = e.touches[1];
      const dist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY);
      touchStateRef.current = { initialDist: dist, initialZoom: previewZoom };
      setIsPinching(true);
    }
  };

  const handleTouchMove = (e) => {
    if (e.touches.length === 2 && touchStateRef.current.initialDist > 0) {
      const t1 = e.touches[0];
      const t2 = e.touches[1];
      const dist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY);
      const ratio = dist / touchStateRef.current.initialDist;
      const targetZoom = touchStateRef.current.initialZoom * ratio;
      setPreviewZoom(Math.min(3.5, Math.max(0.5, targetZoom)));
    }
  };

  const handleTouchEnd = () => {
    touchStateRef.current = { initialDist: 0, initialZoom: 1 };
    setIsPinching(false);
  };

  // Load PDF file into pdfjs-dist
  const loadPdfFile = async (selectedFile) => {
    if (!selectedFile) return;
    setLoading(true);
    setSuccessMsg('');
    try {
      const pdfjsLib = await import('pdfjs-dist');
      try {
        pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('pdfjs-dist/build/pdf.worker.min.mjs', import.meta.url).toString();
      } catch {
        pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version || '4.0.379'}/pdf.worker.min.mjs`;
      }

      const arrayBuffer = await selectedFile.arrayBuffer();
      const doc = await pdfjsLib.getDocument({ data: new Uint8Array(arrayBuffer) }).promise;
      setPdfDoc(doc);
      setNumPages(doc.numPages);
      setCurrentPage(1);
      setFile(selectedFile);
      setPageEdits({});
    } catch (err) {
      console.error('Failed to parse PDF document:', err);
      alert('Failed to load PDF file. Please ensure it is a valid PDF document.');
    } finally {
      setLoading(false);
    }
  };

  // Render current page onto HTML5 canvas & extract text spans
  const renderCurrentPage = useCallback(async () => {
    if (!pdfDoc || !canvasRef.current) return;

    try {
      const page = await pdfDoc.getPage(currentPage);
      const viewport = page.getViewport({ scale });
      setPageViewport(viewport);

      const canvas = canvasRef.current;
      const context = canvas.getContext('2d');
      canvas.width = viewport.width;
      canvas.height = viewport.height;

      const renderContext = {
        canvasContext: context,
        viewport: viewport
      };
      await page.render(renderContext).promise;

      // Extract text content & bounding boxes
      const textContent = await page.getTextContent();
      const styles = textContent.styles || {};
      const pageHeight = page.view[3]; // original unscaled height in PDF points

      const spans = textContent.items.map((item, idx) => {
        if (!item.str || item.str.trim() === '') return null;

        const transform = item.transform; // [scaleX, skewY, skewX, scaleY, translateX, translateY]
        const fontSize = Math.abs(transform[3]) || Math.abs(transform[0]) || 12;

        const pdfX0 = transform[4];
        // PDF Y coordinate origin is bottom-left, invert for top-left screen orientation (aligning with cap-height)
        const pdfY0 = pageHeight - transform[5] - (fontSize * 0.85);
        const rawWidth = item.width > 0 ? item.width : (item.str.length * fontSize * 0.5);
        const rawHeight = item.height > 0 ? item.height : fontSize;
        const pdfWidth = rawWidth * 0.90;
        const pdfHeight = rawHeight * 0.90;

        const pdfX1 = pdfX0 + pdfWidth;
        const pdfY1 = pdfY0 + pdfHeight;

        const fontObj = styles[item.fontName] || {};
        const rawFamily = ((fontObj.fontFamily || item.fontName) || 'Helvetica').toLowerCase();
        
        let detectedFamily = 'Helvetica';
        if (rawFamily.includes('times') || rawFamily.includes('serif') || rawFamily.includes('roman') || rawFamily.includes('cambria') || rawFamily.includes('georgia')) {
          detectedFamily = 'Times-Roman';
        } else if (rawFamily.includes('courier') || rawFamily.includes('mono') || rawFamily.includes('consolas') || rawFamily.includes('menlo')) {
          detectedFamily = 'Courier';
        }

        const isBold = rawFamily.includes('bold') || rawFamily.includes('black') || rawFamily.includes('heavy') || (fontObj.fontWeight && fontObj.fontWeight > 500);
        const isItalic = rawFamily.includes('italic') || rawFamily.includes('oblique') || (fontObj.fontStyle === 'italic');

        return {
          id: `span-${currentPage}-${idx}`,
          str: item.str,
          pdfX0,
          pdfY0,
          pdfX1,
          pdfY1,
          pdfWidth,
          pdfHeight,
          fontSize: +fontSize.toFixed(1),
          fontName: detectedFamily,
          rawFontName: fontObj.fontFamily || item.fontName,
          isBold,
          isItalic
        };
      }).filter(Boolean);

      setTextSpans(spans);
    } catch (err) {
      console.error('Error rendering page:', err);
    }
  }, [pdfDoc, currentPage, scale]);

  useEffect(() => {
    renderCurrentPage();
  }, [renderCurrentPage]);

  // Handle clicking a text span to activate inline editor
  const handleSpanClick = (span) => {
    triggerHaptic('light');
    setActiveSpan(span);
    setEditText(span.str);
    setEditFontSize(span.fontSize);
    setEditColor(span.color || '#000000');
    setEditFontName(span.fontName || 'Helvetica');
    setEditIsBold(Boolean(span.isBold));
    setEditIsItalic(Boolean(span.isItalic));
  };

  // Convert Hex color string to [r, g, b] array
  const hexToRgb = (hex) => {
    let c = hex.replace('#', '');
    if (c.length === 3) c = c.split('').map(x => x + x).join('');
    const num = parseInt(c, 16);
    return [(num >> 16) & 255, (num >> 8) & 255, num & 255];
  };

  // Save edit for active span
  const saveActiveSpanEdit = () => {
    if (!activeSpan) return;
    triggerHaptic('medium');

    const newEdit = {
      id: activeSpan.id.startsWith('edit-') ? activeSpan.id : `edit-${Date.now()}`,
      spanId: activeSpan.id,
      type: 'text',
      bbox: [
        Math.round(activeSpan.pdfX0),
        Math.round(activeSpan.pdfY0),
        Math.round(activeSpan.pdfX1),
        Math.round(activeSpan.pdfY1)
      ],
      original_text: activeSpan.str,
      new_text: editText,
      font_name: editFontName,
      raw_font_name: activeSpan.rawFontName,
      font_size: parseFloat(editFontSize),
      is_bold: editIsBold,
      is_italic: editIsItalic,
      color: hexToRgb(editColor)
    };

    setPageEdits(prev => {
      const currentList = prev[currentPage] || [];
      const filtered = currentList.filter(e => 
        e.id !== newEdit.id && 
        e.spanId !== activeSpan.id &&
        !(Math.abs(e.bbox[0] - newEdit.bbox[0]) < 3 && Math.abs(e.bbox[1] - newEdit.bbox[1]) < 3)
      );
      return {
        ...prev,
        [currentPage]: [...filtered, newEdit]
      };
    });

    setActiveSpan(null);
  };

  // Delete an edit record
  const deleteEdit = (pageNum, editId) => {
    triggerHaptic('light');
    setPageEdits(prev => {
      const currentList = prev[pageNum] || [];
      return {
        ...prev,
        [pageNum]: currentList.filter(e => e.id !== editId)
      };
    });
  };

  // Handle file drop / file select
  const handleFileChange = (e) => {
    const selected = e.target.files?.[0];
    if (selected) loadPdfFile(selected);
  };

  // Submit all edits to backend API
  const handleApplyEdits = async () => {
    if (!file) return;

    // Compile edits payload per page
    const payload = Object.keys(pageEdits).map(pgStr => {
      const pgNum = parseInt(pgStr, 10);
      const edits = pageEdits[pgNum] || [];
      return {
        page_number: pgNum,
        edits: edits.map(e => {
          if (e.type === 'text') {
            return {
              type: 'text',
              bbox: e.bbox,
              new_text: e.new_text,
              font_name: e.font_name,
              font_size: e.font_size,
              color: e.color
            };
          } else {
            return {
              type: 'image',
              bbox: e.bbox,
              new_image_base64: e.new_image_base64
            };
          }
        })
      };
    }).filter(p => p.edits.length > 0);

    if (payload.length === 0) {
      alert('Please tap on any text in the document and make at least one edit before applying.');
      return;
    }

    setExporting(true);
    setSuccessMsg('');

    try {
      const response = await applyPdfEdits(file, payload);
      
      // Create blob and download/open using native helper (compatible with Capacitor & Web)
      const blob = new Blob([response.data], { type: 'application/pdf' });
      const blobUrl = URL.createObjectURL(blob);
      const sanitizedName = file.name.replace(/\.pdf$/i, '');
      const downloadFilename = `edited_${sanitizedName}.pdf`;

      await downloadAndOpenFile(blobUrl, downloadFilename, 'application/pdf');

      // Re-load the new edited PDF into the editor viewer live
      try {
        const updatedFile = new File([blob], downloadFilename, { type: 'application/pdf' });
        await loadPdfFile(updatedFile);
      } catch (reloadErr) {
        console.warn('Live reload notice:', reloadErr);
      }

      setSuccessMsg('PDF edited & saved successfully!');
      triggerHaptic('success');
      showNativeToast('PDF saved successfully!');
    } catch (err) {
      console.error('Error applying PDF edits:', err);
      triggerHaptic('error');
      alert('Failed to process PDF edits: ' + (err.message || 'Please try again.'));
    } finally {
      setExporting(false);
    }
  };

  const totalEditsCount = Object.values(pageEdits).reduce((sum, arr) => sum + arr.length, 0);

  return (
    <div className="pdf-editor-container">
      {/* Top Toolbar */}
      <div className="editor-toolbar">
        <div className="toolbar-group">
          <div className="toolbar-title">
            <Sparkles size={20} color="#818cf8" />
            PDF Editor
          </div>

          <div className="limit-badge" style={{ background: 'rgba(16, 185, 129, 0.12)', color: '#34d399', borderColor: 'rgba(16, 185, 129, 0.3)' }}>
            <ShieldCheck size={15} />
            100% Private Client-Side Engine
          </div>
        </div>

        {file && (
          <div className="toolbar-group">
            {/* Page Navigation */}
            <button 
              className="toolbar-btn" 
              title="Previous Page"
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))} 
              disabled={currentPage <= 1}
            >
              <ChevronLeft size={16} />
            </button>
            <span style={{ fontSize: '0.9rem', color: '#94a3b8', minWidth: '70px', textAlign: 'center' }}>
              Page {currentPage} of {numPages}
            </span>
            <button 
              className="toolbar-btn" 
              title="Next Page"
              onClick={() => setCurrentPage(p => Math.min(numPages, p + 1))} 
              disabled={currentPage >= numPages}
            >
              <ChevronRight size={16} />
            </button>
          </div>
        )}

        <div className="toolbar-group">
          {file && (
            <button 
              className="toolbar-btn btn-primary" 
              onClick={handleApplyEdits} 
              disabled={exporting || totalEditsCount === 0}
            >
              <Download size={16} />
              {exporting ? 'Processing...' : `Apply & Download (${totalEditsCount})`}
            </button>
          )}
        </div>
      </div>



      {/* Success Notification Banner */}
      {successMsg && (
        <div className="rate-limit-alert" style={{ background: 'rgba(16, 185, 129, 0.15)', borderColor: 'rgba(16, 185, 129, 0.3)', color: '#34d399' }}>
          <CheckCircle2 size={18} style={{ flexShrink: 0 }} />
          <div style={{ flex: 1 }}>{successMsg}</div>
          <button onClick={() => setSuccessMsg('')} style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}>
            <X size={16} />
          </button>
        </div>
      )}

      {/* Main Work Area */}
      <div className={`editor-main-area ${!file ? 'editor-main-area--empty' : ''}`}>
        {!file ? (
          <div className="upload-placeholder" onClick={() => fileInputRef.current?.click()}>
            <FileUp size={44} color="#818cf8" style={{ marginBottom: '0.85rem' }} />
            <h3 style={{ fontSize: '1.15rem', margin: '0 0 0.4rem 0', color: 'var(--text-main, #f8fafc)' }}>
              Upload PDF to Edit Text & Objects
            </h3>
            <p style={{ margin: 0, color: 'var(--text-muted, #94a3b8)', fontSize: '0.875rem' }}>
              Click or drag and drop a PDF file to begin in-place editing
            </p>
            <input 
              type="file" 
              ref={fileInputRef} 
              style={{ display: 'none' }} 
              accept="application/pdf" 
              onChange={handleFileChange} 
            />
          </div>
        ) : (
          <>
            {/* Viewport & Canvas Overlay with Pinch Zoom & Pan */}
            <div 
              ref={viewportRef}
              className="editor-viewport"
              onTouchStart={handleTouchStart}
              onTouchMove={handleTouchMove}
              onTouchEnd={handleTouchEnd}
              onDoubleClick={() => setPreviewZoom(1)}
            >
              <div 
                className="canvas-wrapper" 
                style={{ 
                  width: pageViewport?.width, 
                  height: pageViewport?.height,
                  transform: `scale(${previewZoom})`,
                  transition: isPinching ? 'none' : 'transform 0.12s ease-out'
                }}
              >
                <canvas ref={canvasRef} className="pdf-canvas" />

                {/* Interactive Text Span Detection Overlay Layer */}
                <div className="text-overlay-layer">
                  {textSpans.map(span => {
                    const isBeingEdited = activeSpan?.id === span.id;
                    const screenX = span.pdfX0 * scale;
                    const screenY = span.pdfY0 * scale;
                    const screenW = Math.max(6, span.pdfWidth * scale);
                    const screenH = Math.max(8, span.pdfHeight * scale);

                    return (
                      <div
                        key={span.id}
                        className={`text-span-box ${isBeingEdited ? 'editing' : ''}`}
                        style={{
                          left: `${screenX}px`,
                          top: `${screenY}px`,
                          width: `${screenW}px`,
                          height: `${screenH}px`,
                        }}
                        title={`Click to edit: "${span.str}"`}
                        onClick={() => handleSpanClick(span)}
                      />
                    );
                  })}
                </div>

                {/* Live Staged Edits Visual Overlay on Canvas */}
                {(pageEdits[currentPage] || []).map(edit => {
                  const screenX = edit.bbox[0] * scale;
                  const screenY = edit.bbox[1] * scale;
                  const screenW = Math.max(16, (edit.bbox[2] - edit.bbox[0]) * scale);
                  const screenH = Math.max(14, (edit.bbox[3] - edit.bbox[1]) * scale);
                  const maxAllowedW = Math.max(30, (pageViewport?.width || 595 * scale) - screenX - 6);
                  const isBeingEdited = activeSpan?.id === edit.id || activeSpan?.spanId === edit.spanId;

                  if (isBeingEdited) return null;

                  return (
                    <div
                      key={edit.id}
                      className="live-edit-text-overlay"
                      style={{
                        position: 'absolute',
                        left: `${screenX}px`,
                        top: `${screenY}px`,
                        minWidth: `${screenW}px`,
                        maxWidth: `${maxAllowedW}px`,
                        height: `${screenH}px`,
                        backgroundColor: '#ffffff',
                        color: `rgb(${edit.color[0]}, ${edit.color[1]}, ${edit.color[2]})`,
                        fontFamily: edit.font_name === 'Courier' ? 'Courier, monospace' : edit.font_name === 'Times-Roman' ? '"Times New Roman", serif' : 'Helvetica, Arial, sans-serif',
                        fontWeight: edit.is_bold ? 'bold' : 'normal',
                        fontStyle: edit.is_italic ? 'italic' : 'normal',
                        fontSize: `${edit.font_size * scale}px`,
                        lineHeight: `${screenH}px`,
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        zIndex: 6,
                        cursor: 'pointer',
                        padding: '0 3px',
                        outline: '1.5px solid #6366f1',
                        borderRadius: '2px',
                        boxShadow: '0 2px 6px rgba(0, 0, 0, 0.15)',
                        display: 'flex',
                        alignItems: 'center',
                        userSelect: 'none'
                      }}
                      title={`Edited: "${edit.new_text}" (Tap to re-edit)`}
                      onClick={(e) => {
                        e.stopPropagation();
                        triggerHaptic('light');
                        setActiveSpan({
                          id: edit.id,
                          spanId: edit.spanId,
                          str: edit.original_text || edit.new_text,
                          pdfX0: edit.bbox[0],
                          pdfY0: edit.bbox[1],
                          pdfX1: edit.bbox[2],
                          pdfY1: edit.bbox[3],
                          fontSize: edit.font_size,
                          fontName: edit.font_name,
                          isBold: edit.is_bold,
                          isItalic: edit.is_italic
                        });
                        setEditText(edit.new_text);
                        setEditFontSize(edit.font_size);
                        setEditIsBold(Boolean(edit.is_bold));
                        setEditIsItalic(Boolean(edit.is_italic));
                        const rgbToHex = (r, g, b) => '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('');
                        setEditColor(rgbToHex(edit.color[0], edit.color[1], edit.color[2]));
                        setEditFontName(edit.font_name);
                      }}
                    >
                      {edit.new_text}
                    </div>
                  );
                })}

                {/* Real-time active typing visual preview on canvas */}
                {activeSpan && (
                  <div
                    style={{
                      position: 'absolute',
                      left: `${activeSpan.pdfX0 * scale}px`,
                      top: `${activeSpan.pdfY0 * scale}px`,
                      minWidth: `${Math.max(12, (activeSpan.pdfX1 - activeSpan.pdfX0) * scale)}px`,
                      maxWidth: `${Math.max(30, (pageViewport?.width || 595 * scale) - (activeSpan.pdfX0 * scale) - 6)}px`,
                      height: `${Math.max(14, (activeSpan.pdfY1 - activeSpan.pdfY0) * scale)}px`,
                      backgroundColor: '#ffffff',
                      color: editColor,
                      fontFamily: editFontName === 'Courier' ? 'Courier, monospace' : editFontName === 'Times-Roman' ? '"Times New Roman", serif' : 'Helvetica, Arial, sans-serif',
                      fontWeight: editIsBold ? 'bold' : 'normal',
                      fontStyle: editIsItalic ? 'italic' : 'normal',
                      fontSize: `${parseFloat(editFontSize || 12) * scale}px`,
                      lineHeight: `${Math.max(14, (activeSpan.pdfY1 - activeSpan.pdfY0) * scale)}px`,
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      zIndex: 7,
                      padding: '0 3px',
                      outline: '2px solid #818cf8',
                      borderRadius: '2px',
                      boxShadow: '0 0 10px rgba(99, 102, 241, 0.4)',
                      display: 'flex',
                      alignItems: 'center',
                      pointerEvents: 'none'
                    }}
                  >
                    {editText || '\u00A0'}
                  </div>
                )}

              </div>

              {/* Responsive Floating Text Editor Panel */}
              {activeSpan && (
                <div 
                  className="inline-text-editor-container"
                  onTouchStart={e => e.stopPropagation()}
                  onTouchMove={e => e.stopPropagation()}
                >
                  <div className="inline-text-editor">
                    <div className="inline-text-editor__header">
                      <div className="inline-text-editor__title">
                        <Sparkles size={13} color="#818cf8" />
                        <span>Edit Text Element</span>
                      </div>
                      <button 
                        type="button"
                        className="inline-text-editor__close"
                        onClick={() => setActiveSpan(null)}
                        aria-label="Close edit"
                      >
                        <X size={14} />
                      </button>
                    </div>

                    <input
                      type="text"
                      className="editor-input"
                      value={editText}
                      onChange={e => setEditText(e.target.value)}
                      placeholder="Enter new text..."
                      autoFocus
                    />

                    <div className="editor-controls-row">
                      {/* Font Size Stepper */}
                      <div className="editor-control-item">
                        <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>Size:</span>
                        <div className="editor-stepper">
                          <button
                            type="button"
                            className="stepper-btn"
                            onClick={() => setEditFontSize(prev => Math.max(6, (parseFloat(prev) || 12) - 1))}
                          >
                            <Minus size={11} />
                          </button>
                          <span className="stepper-val">{editFontSize}</span>
                          <button
                            type="button"
                            className="stepper-btn"
                            onClick={() => setEditFontSize(prev => Math.min(72, (parseFloat(prev) || 12) + 1))}
                          >
                            <Plus size={11} />
                          </button>
                        </div>
                      </div>

                      {/* Font Style Toggles */}
                      <div className="editor-btn-group">
                        <button
                          type="button"
                          className={`toolbar-btn inline-editor-style-btn ${editIsBold ? 'active' : ''}`}
                          style={{ fontWeight: 'bold' }}
                          onClick={() => {
                            triggerHaptic('light');
                            setEditIsBold(!editIsBold);
                          }}
                          title="Toggle Bold"
                        >
                          B
                        </button>
                        <button
                          type="button"
                          className={`toolbar-btn inline-editor-style-btn ${editIsItalic ? 'active' : ''}`}
                          style={{ fontStyle: 'italic' }}
                          onClick={() => {
                            triggerHaptic('light');
                            setEditIsItalic(!editIsItalic);
                          }}
                          title="Toggle Italic"
                        >
                          I
                        </button>
                      </div>

                      {/* Font Family Selector */}
                      <select
                        className="editor-font-select"
                        value={editFontName}
                        onChange={e => setEditFontName(e.target.value)}
                      >
                        <option value="Helvetica">Helvetica (Sans)</option>
                        <option value="Times-Roman">Times (Serif)</option>
                        <option value="Courier">Courier (Mono)</option>
                      </select>
                    </div>

                    {/* Quick Color Palette Swatches */}
                    <div className="editor-color-swatches-row">
                      <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>Color:</span>
                      <div className="color-swatches-list">
                        {['#000000', '#1e293b', '#2563eb', '#dc2626', '#16a34a', '#d97706', '#7c3aed'].map(c => (
                          <button
                            key={c}
                            type="button"
                            className={`color-swatch-dot ${editColor.toLowerCase() === c.toLowerCase() ? 'active' : ''}`}
                            style={{ backgroundColor: c }}
                            onClick={() => {
                              triggerHaptic('light');
                              setEditColor(c);
                            }}
                            title={c}
                          />
                        ))}
                        <label className="color-picker-label" title="Custom color">
                          <Palette size={12} color="#94a3b8" />
                          <input
                            type="color"
                            value={editColor}
                            onChange={e => setEditColor(e.target.value)}
                            className="hidden-color-input"
                          />
                        </label>
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="editor-actions-row">
                      <button 
                        type="button" 
                        className="toolbar-btn btn-primary inline-editor-action-btn" 
                        style={{ flex: 1 }} 
                        onClick={saveActiveSpanEdit}
                      >
                        <CheckCircle2 size={14} />
                        <span>Save Edit</span>
                      </button>
                      {activeSpan?.id?.startsWith('edit-') && (
                        <button
                          type="button"
                          className="toolbar-btn inline-editor-action-btn"
                          style={{ color: '#ef4444', borderColor: 'rgba(239, 68, 68, 0.3)' }}
                          onClick={() => {
                            deleteEdit(currentPage, activeSpan.id);
                            setActiveSpan(null);
                          }}
                          title="Delete this edit"
                        >
                          Delete
                        </button>
                      )}
                      <button 
                        type="button" 
                        className="toolbar-btn inline-editor-action-btn" 
                        onClick={() => setActiveSpan(null)}
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Floating Reset Zoom Badge */}
              {previewZoom !== 1 && (
                <button 
                  className="preview-zoom-reset-btn"
                  onClick={() => setPreviewZoom(1)}
                  title="Double click canvas or tap here to reset zoom"
                >
                  {Math.round(previewZoom * 100)}% • Reset Zoom
                </button>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
