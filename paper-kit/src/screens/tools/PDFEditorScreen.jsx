import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
  FileUp, Download, ZoomIn, ZoomOut, RotateCcw, ChevronLeft, ChevronRight, 
  Type, Image as ImageIcon, Trash2, CheckCircle2, AlertTriangle, ShieldAlert, Sparkles, X 
} from 'lucide-react';
import { getEditorLimits, applyPdfEdits } from '../../services/tools';
import './PDFEditorScreen.css';

export default function PDFEditorScreen() {
  const [file, setFile] = useState(null);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [numPages, setNumPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [scale, setScale] = useState(1.2);
  const [textSpans, setTextSpans] = useState([]);
  const [pageViewport, setPageViewport] = useState(null);

  // Remaining daily edits rate limit state
  const [limits, setLimits] = useState({ remaining: 3, limit: 3 });
  const [rateLimitError, setRateLimitError] = useState(null);

  // Active edits per page: { [pageNum]: [ { id, type, bbox, new_text, font_name, font_size, color, new_image_base64 } ] }
  const [pageEdits, setPageEdits] = useState({});

  // Active text span being edited inline
  const [activeSpan, setActiveSpan] = useState(null);
  const [editText, setEditText] = useState('');
  const [editFontSize, setEditFontSize] = useState(12);
  const [editColor, setEditColor] = useState('#000000');
  const [editFontName, setEditFontName] = useState('Helvetica');

  // Status flags
  const [loading, setLoading] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');

  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);
  const imageInputRef = useRef(null);

  // Fetch daily rate limits on mount
  const refreshLimits = useCallback(async () => {
    try {
      const data = await getEditorLimits();
      if (data && typeof data.remaining === 'number') {
        setLimits(data);
      }
    } catch (e) {
      console.warn('Failed to fetch editor limits:', e);
    }
  }, []);

  useEffect(() => {
    refreshLimits();
  }, [refreshLimits]);

  // Load PDF file into pdfjs-dist
  const loadPdfFile = async (selectedFile) => {
    if (!selectedFile) return;
    setLoading(true);
    setRateLimitError(null);
    setSuccessMsg('');
    try {
      const pdfjsLib = await import('pdfjs-dist');
      try {
        pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('pdfjs-dist/build/pdf.worker.min.mjs', import.meta.url).toString();
      } catch (e) {
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
      const pageHeight = page.view[3]; // original unscaled height in PDF points

      const spans = textContent.items.map((item, idx) => {
        if (!item.str || item.str.trim() === '') return null;

        const transform = item.transform; // [scaleX, skewY, skewX, scaleY, translateX, translateY]
        const fontSize = Math.abs(transform[3]) || 12;

        const pdfX0 = transform[4];
        // PDF Y coordinate origin is bottom-left, invert for top-left screen orientation
        const pdfY0 = pageHeight - transform[5] - fontSize;
        const pdfWidth = item.width > 0 ? item.width : (item.str.length * fontSize * 0.5);
        const pdfHeight = item.height > 0 ? item.height : fontSize;

        const pdfX1 = pdfX0 + pdfWidth;
        const pdfY1 = pdfY0 + pdfHeight;

        return {
          id: `span-${currentPage}-${idx}`,
          str: item.str,
          pdfX0,
          pdfY0,
          pdfX1,
          pdfY1,
          pdfWidth,
          pdfHeight,
          fontSize,
          fontName: item.fontName || 'Helvetica'
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
    setActiveSpan(span);
    setEditText(span.str);
    setEditFontSize(Math.round(span.fontSize));
    setEditColor('#000000');
    setEditFontName('Helvetica');
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

    const newEdit = {
      id: `edit-${Date.now()}`,
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
      font_size: parseFloat(editFontSize),
      color: hexToRgb(editColor)
    };

    setPageEdits(prev => {
      const currentList = prev[currentPage] || [];
      return {
        ...prev,
        [currentPage]: [...currentList, newEdit]
      };
    });

    setActiveSpan(null);
  };

  // Delete an edit record
  const deleteEdit = (pageNum, editId) => {
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

  // Replace image via file selection
  const handleImageUpload = (e) => {
    const imgFile = e.target.files?.[0];
    if (!imgFile) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64Img = reader.result;
      // Add default image overlay edit at center of page
      const defaultBbox = [100, 100, 300, 300];
      const imgEdit = {
        id: `edit-img-${Date.now()}`,
        type: 'image',
        bbox: defaultBbox,
        new_image_base64: base64Img
      };

      setPageEdits(prev => {
        const currentList = prev[currentPage] || [];
        return {
          ...prev,
          [currentPage]: [...currentList, imgEdit]
        };
      });
    };
    reader.readAsDataURL(imgFile);
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
      alert('Please add at least one text or image edit before exporting.');
      return;
    }

    setExporting(true);
    setRateLimitError(null);
    setSuccessMsg('');

    try {
      const response = await applyPdfEdits(file, payload);
      
      // Download response blob as file
      const blob = new Blob([response.data], { type: 'application/pdf' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `edited_${file.name}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      setSuccessMsg('PDF edited & downloaded successfully!');
      
      // Update rate limits count
      refreshLimits();
    } catch (err) {
      console.error('Error applying PDF edits:', err);
      if (err.response && err.response.status === 429) {
        const errorDetail = err.response.data?.detail || 'Daily free limit reached (3/3). Resets at midnight.';
        setRateLimitError(errorDetail);
        refreshLimits();
      } else {
        alert('Failed to process PDF edits. Please try again.');
      }
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
            <Sparkles className="w-5 h-5 text-indigo-400" />
            PDF Editor
          </div>

          <div className={`limit-badge ${limits.remaining === 0 ? 'exhausted' : limits.remaining === 1 ? 'low' : ''}`}>
            <ShieldAlert className="w-4 h-4" />
            Remaining edits today: {limits.remaining} / {limits.limit}
          </div>
        </div>

        {file && (
          <div className="toolbar-group">
            {/* Page Navigation */}
            <button 
              className="toolbar-btn" 
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))} 
              disabled={currentPage <= 1}
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span style={{ fontSize: '0.9rem', color: '#94a3b8' }}>
              Page {currentPage} of {numPages}
            </span>
            <button 
              className="toolbar-btn" 
              onClick={() => setCurrentPage(p => Math.min(numPages, p + 1))} 
              disabled={currentPage >= numPages}
            >
              <ChevronRight className="w-4 h-4" />
            </button>

            {/* Zoom Controls */}
            <button className="toolbar-btn" onClick={() => setScale(s => Math.max(0.6, s - 0.2))}>
              <ZoomOut className="w-4 h-4" />
            </button>
            <span style={{ fontSize: '0.85rem', color: '#94a3b8' }}>{Math.round(scale * 100)}%</span>
            <button className="toolbar-btn" onClick={() => setScale(s => Math.min(2.5, s + 0.2))}>
              <ZoomIn className="w-4 h-4" />
            </button>

            {/* Add Image Tool */}
            <button className="toolbar-btn" onClick={() => imageInputRef.current?.click()}>
              <ImageIcon className="w-4 h-4" />
              Add Image
            </button>
            <input 
              type="file" 
              ref={imageInputRef} 
              style={{ display: 'none' }} 
              accept="image/*" 
              onChange={handleImageUpload} 
            />

            {/* Change File */}
            <button className="toolbar-btn" onClick={() => fileInputRef.current?.click()}>
              <FileUp className="w-4 h-4" />
              Change PDF
            </button>
          </div>
        )}

        <div className="toolbar-group">
          {file && (
            <button 
              className="toolbar-btn btn-primary" 
              onClick={handleApplyEdits} 
              disabled={exporting || totalEditsCount === 0 || limits.remaining === 0}
            >
              <Download className="w-4 h-4" />
              {exporting ? 'Processing...' : `Apply & Download (${totalEditsCount})`}
            </button>
          )}
        </div>
      </div>

      {/* Rate Limit Blocked Alert Banner */}
      {rateLimitError && (
        <div className="rate-limit-alert">
          <AlertTriangle className="w-5 h-5 flex-shrink-0" />
          <div style={{ flex: 1 }}>{rateLimitError}</div>
          <button onClick={() => setRateLimitError(null)} style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}>
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Success Notification Banner */}
      {successMsg && (
        <div className="rate-limit-alert" style={{ background: 'rgba(16, 185, 129, 0.15)', borderColor: 'rgba(16, 185, 129, 0.3)', color: '#34d399' }}>
          <CheckCircle2 className="w-5 h-5 flex-shrink-0" />
          <div style={{ flex: 1 }}>{successMsg}</div>
          <button onClick={() => setSuccessMsg('')} style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer' }}>
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Main Work Area */}
      <div className="editor-main-area">
        {!file ? (
          <div className="upload-placeholder" onClick={() => fileInputRef.current?.click()}>
            <FileUp className="w-16 h-16 text-indigo-400 mb-4" />
            <h3 style={{ fontSize: '1.2rem', margin: '0 0 0.5rem 0', color: '#f8fafc' }}>
              Upload PDF to Edit Text & Objects
            </h3>
            <p style={{ margin: 0, color: '#94a3b8', fontSize: '0.9rem' }}>
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
            {/* Viewport & Canvas Overlay */}
            <div className="editor-viewport">
              <div className="canvas-wrapper" style={{ width: pageViewport?.width, height: pageViewport?.height }}>
                <canvas ref={canvasRef} className="pdf-canvas" />

                {/* Interactive Text Span Detection Overlay Layer */}
                <div className="text-overlay-layer">
                  {textSpans.map(span => {
                    const isBeingEdited = activeSpan?.id === span.id;
                    const screenX = span.pdfX0 * scale;
                    const screenY = span.pdfY0 * scale;
                    const screenW = Math.max(12, span.pdfWidth * scale);
                    const screenH = Math.max(14, span.pdfHeight * scale);

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

                {/* Inline Text Editor Popover */}
                {activeSpan && (
                  <div
                    className="inline-text-editor"
                    style={{
                      left: `${Math.min(activeSpan.pdfX0 * scale, (pageViewport?.width || 300) - 280)}px`,
                      top: `${activeSpan.pdfY0 * scale + 24}px`,
                    }}
                  >
                    <div style={{ fontSize: '0.8rem', color: '#94a3b8', fontWeight: 600 }}>
                      Edit Selected Text Span
                    </div>
                    <input
                      type="text"
                      className="editor-input"
                      value={editText}
                      onChange={e => setEditText(e.target.value)}
                      autoFocus
                    />
                    <div className="editor-controls-row">
                      <label style={{ fontSize: '0.8rem', color: '#cbd5e1' }}>
                        Size:
                        <input
                          type="number"
                          value={editFontSize}
                          onChange={e => setEditFontSize(e.target.value)}
                        />
                      </label>
                      <label style={{ fontSize: '0.8rem', color: '#cbd5e1', display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                        Color:
                        <input
                          type="color"
                          value={editColor}
                          onChange={e => setEditColor(e.target.value)}
                        />
                      </label>
                      <select
                        value={editFontName}
                        onChange={e => setEditFontName(e.target.value)}
                        style={{ background: '#0f172a', color: '#f8fafc', border: '1px solid #334155', borderRadius: '4px', padding: '0.2rem' }}
                      >
                        <option value="Helvetica">Helvetica</option>
                        <option value="Times-Roman">Times</option>
                        <option value="Courier">Courier</option>
                      </select>
                    </div>
                    <div className="editor-controls-row" style={{ marginTop: '0.25rem' }}>
                      <button className="toolbar-btn btn-primary" style={{ flex: 1 }} onClick={saveActiveSpanEdit}>
                        Save Edit
                      </button>
                      <button className="toolbar-btn" onClick={() => setActiveSpan(null)}>
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Sidebar: Pending Edits Summary */}
            <div className="sidebar-edits">
              <div className="edits-header">
                <span>Staged Edits ({totalEditsCount})</span>
                {totalEditsCount > 0 && (
                  <button 
                    onClick={() => setPageEdits({})} 
                    style={{ background: 'none', border: 'none', color: 'rgba(255,255,255,0.5)', cursor: 'pointer', fontSize: '0.8rem' }}
                  >
                    Clear All
                  </button>
                )}
              </div>

              {totalEditsCount === 0 ? (
                <div className="empty-edits-state">
                  Click any highlighted text on the canvas or click "Add Image" to stage changes.
                </div>
              ) : (
                Object.keys(pageEdits).map(pgNumStr => {
                  const pgNum = parseInt(pgNumStr, 10);
                  const edits = pageEdits[pgNum] || [];
                  if (edits.length === 0) return null;

                  return (
                    <div key={`pg-summary-${pgNum}`}>
                      <div style={{ fontSize: '0.8rem', fontWeight: 600, color: '#64748b', marginBottom: '0.4rem' }}>
                        Page {pgNum}
                      </div>
                      {edits.map(edit => (
                        <div key={edit.id} className="edit-item-card">
                          <div className="edit-item-header">
                            <span>{edit.type === 'text' ? 'Text Replacement' : 'Image Overlay'}</span>
                            <button className="edit-item-delete" onClick={() => deleteEdit(pgNum, edit.id)}>
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                          {edit.type === 'text' ? (
                            <>
                              <div style={{ color: '#94a3b8', textDecoration: 'line-through' }}>
                                "{edit.original_text}"
                              </div>
                              <div style={{ color: '#34d399', fontWeight: 600 }}>
                                ➜ "{edit.new_text}"
                              </div>
                            </>
                          ) : (
                            <div style={{ color: '#cbd5e1' }}>
                              Image attached to bbox [{edit.bbox.join(', ')}]
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  );
                })
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
