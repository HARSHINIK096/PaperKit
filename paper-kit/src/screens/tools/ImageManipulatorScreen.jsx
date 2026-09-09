import { useState, useEffect, useRef, useCallback } from 'react';
import { 
  Sliders, Image as ImageIcon, Download, RotateCw, FlipHorizontal, FlipVertical, 
  RefreshCw, Sun, Sparkles, Upload 
} from 'lucide-react';
import './ImageManipulatorScreen.css';

export default function ImageManipulatorScreen() {
  const [imageFile, setImageFile] = useState(null);
  const [imageElement, setImageElement] = useState(null);

  // Manipulator controls state
  const [brightness, setBrightness] = useState(100);
  const [contrast, setContrast] = useState(100);
  const [saturation, setSaturation] = useState(100);
  const [blur, setBlur] = useState(0);
  const [grayscale, setGrayscale] = useState(0);
  const [sepia, setSepia] = useState(0);
  const [invert, setInvert] = useState(0);
  const [rotation, setRotation] = useState(0);
  const [flipH, setFlipH] = useState(false);
  const [flipV, setFlipV] = useState(false);

  const [outputFormat, setOutputFormat] = useState('image/png');

  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);

  const handleImageSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      setImageElement(img);
      setImageFile(file);
      resetControls();
    };
    img.src = URL.createObjectURL(file);
  };

  const resetControls = () => {
    setBrightness(100);
    setContrast(100);
    setSaturation(100);
    setBlur(0);
    setGrayscale(0);
    setSepia(0);
    setInvert(0);
    setRotation(0);
    setFlipH(false);
    setFlipV(false);
  };

  const drawCanvas = useCallback(() => {
    if (!imageElement || !canvasRef.current) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');

    const is90or270 = rotation % 180 !== 0;
    canvas.width = is90or270 ? imageElement.height : imageElement.width;
    canvas.height = is90or270 ? imageElement.width : imageElement.height;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();

    // Apply CSS filters directly to canvas context
    ctx.filter = `brightness(${brightness}%) contrast(${contrast}%) saturate(${saturation}%) blur(${blur}px) grayscale(${grayscale}%) sepia(${sepia}%) invert(${invert}%)`;

    // Apply transformations (rotation & flips)
    ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.rotate((rotation * Math.PI) / 180);
    ctx.scale(flipH ? -1 : 1, flipV ? -1 : 1);

    ctx.drawImage(
      imageElement,
      -imageElement.width / 2,
      -imageElement.height / 2
    );

    ctx.restore();
  }, [imageElement, brightness, contrast, saturation, blur, grayscale, sepia, invert, rotation, flipH, flipV]);

  useEffect(() => {
    drawCanvas();
  }, [drawCanvas]);

  const handleDownload = () => {
    if (!canvasRef.current || !imageFile) return;

    const ext = outputFormat === 'image/jpeg' ? 'jpg' : outputFormat === 'image/webp' ? 'webp' : 'png';
    const link = document.createElement('a');
    link.download = `adjusted_${imageFile.name.replace(/\.[^/.]+$/, '')}.${ext}`;
    link.href = canvasRef.current.toDataURL(outputFormat, 0.92);
    link.click();
  };

  return (
    <div className="image-manipulator-container">
      {/* Toolbar */}
      <div className="manipulator-toolbar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 700, fontSize: '1.1rem', color: '#f8fafc' }}>
          <Sliders className="w-5 h-5 text-indigo-400" />
          Image Adjust &amp; Manipulator
        </div>

        {imageFile && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <select
              value={outputFormat}
              onChange={e => setOutputFormat(e.target.value)}
              style={{ background: '#0f172a', color: '#f8fafc', border: '1px solid #334155', borderRadius: '8px', padding: '0.4rem 0.6rem' }}
            >
              <option value="image/png">PNG Format</option>
              <option value="image/jpeg">JPG Format</option>
              <option value="image/webp">WebP Format</option>
            </select>

            <button className="toolbar-btn" onClick={resetControls}>
              <RefreshCw className="w-4 h-4" />
              Reset All
            </button>

            <button className="toolbar-btn" onClick={() => fileInputRef.current?.click()}>
              <Upload className="w-4 h-4" />
              Change Image
            </button>

            <button className="toolbar-btn btn-primary" onClick={handleDownload}>
              <Download className="w-4 h-4" />
              Download Adjusted Image
            </button>
          </div>
        )}
      </div>

      {/* Main Container */}
      <div className={`manipulator-main ${!imageElement ? 'manipulator-main--empty' : ''}`}>
        {!imageElement ? (
          <div className="upload-placeholder" onClick={() => fileInputRef.current?.click()}>
            <ImageIcon className="w-16 h-16 text-indigo-400 mb-4" />
            <h3 style={{ fontSize: '1.2rem', margin: '0 0 0.5rem 0', color: '#f8fafc' }}>
              Upload Image to Adjust Brightness, Contrast &amp; Filters
            </h3>
            <p style={{ margin: 0, color: '#94a3b8', fontSize: '0.9rem' }}>
              Supports PNG, JPG, WebP, HEIC &amp; BMP images
            </p>
            <input
              type="file"
              ref={fileInputRef}
              style={{ display: 'none' }}
              accept="image/*"
              onChange={handleImageSelect}
            />
          </div>
        ) : (
          <>
            {/* Live Canvas Viewport */}
            <div className="manipulator-viewport">
              <canvas ref={canvasRef} className="preview-canvas" />
            </div>

            {/* Adjustment Controls Sidebar */}
            <div className="manipulator-controls-sidebar">
              <div>
                <div className="control-group-title">
                  <Sun className="w-4 h-4 text-amber-400" />
                  Color &amp; Light Adjustments
                </div>

                <div className="control-slider-item">
                  <div className="control-slider-label">
                    <span>Brightness</span>
                    <span>{brightness}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="200"
                    value={brightness}
                    onChange={e => setBrightness(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>

                <div className="control-slider-item" style={{ marginTop: '0.75rem' }}>
                  <div className="control-slider-label">
                    <span>Contrast</span>
                    <span>{contrast}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="200"
                    value={contrast}
                    onChange={e => setContrast(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>

                <div className="control-slider-item" style={{ marginTop: '0.75rem' }}>
                  <div className="control-slider-label">
                    <span>Saturation</span>
                    <span>{saturation}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="200"
                    value={saturation}
                    onChange={e => setSaturation(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>
              </div>

              <div>
                <div className="control-group-title">
                  <Sparkles className="w-4 h-4 text-indigo-400" />
                  Effects &amp; Filters
                </div>

                <div className="control-slider-item">
                  <div className="control-slider-label">
                    <span>Blur</span>
                    <span>{blur}px</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="20"
                    value={blur}
                    onChange={e => setBlur(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>

                <div className="control-slider-item" style={{ marginTop: '0.75rem' }}>
                  <div className="control-slider-label">
                    <span>Grayscale</span>
                    <span>{grayscale}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={grayscale}
                    onChange={e => setGrayscale(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>

                <div className="control-slider-item" style={{ marginTop: '0.75rem' }}>
                  <div className="control-slider-label">
                    <span>Sepia</span>
                    <span>{sepia}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={sepia}
                    onChange={e => setSepia(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>

                <div className="control-slider-item" style={{ marginTop: '0.75rem' }}>
                  <div className="control-slider-label">
                    <span>Invert</span>
                    <span>{invert}%</span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={invert}
                    onChange={e => setInvert(Number(e.target.value))}
                    className="control-slider-input"
                  />
                </div>
              </div>

              <div>
                <div className="control-group-title">
                  <RotateCw className="w-4 h-4 text-emerald-400" />
                  Rotate &amp; Flip
                </div>

                <div className="transform-buttons-grid">
                  <button className="toolbar-btn" onClick={() => setRotation(r => (r + 90) % 360)}>
                    <RotateCw className="w-4 h-4" />
                    Rotate 90°
                  </button>
                  <button className="toolbar-btn" onClick={() => setFlipH(f => !f)}>
                    <FlipHorizontal className="w-4 h-4" />
                    Flip H
                  </button>
                  <button className="toolbar-btn" onClick={() => setFlipV(f => !f)}>
                    <FlipVertical className="w-4 h-4" />
                    Flip V
                  </button>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
