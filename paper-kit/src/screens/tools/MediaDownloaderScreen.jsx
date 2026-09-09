import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Video, Music, Download, Zap, HardDrive, ShieldCheck, DownloadCloud, AlertCircle, RefreshCw } from 'lucide-react';
import Toast from '../../components/ui/Toast';
import { useToast } from '../../hooks/useToast';
import { downloadAndOpenFile } from '../../services/native';
import FeatureTipsSwipeStack from '../../components/ui/FeatureTipsSwipeStack';
import '../ai/ai-screen.css';

const TOOL_TIPS = [
  {
    icon: <DownloadCloud size={20} />,
    title: 'High Quality',
    description: 'Download the best available video/audio quality.'
  },
  {
    icon: <HardDrive size={20} />,
    title: 'Save Offline',
    description: 'Store files locally on your device for offline enjoyment.'
  },
  {
    icon: <Music size={20} />,
    title: 'Audio Extraction',
    description: 'Rip high-bitrate MP3s directly from video or track links.'
  },
  {
    icon: <Zap size={20} />,
    title: 'Fast Processing',
    description: 'High throughput streaming engine.'
  },
  {
    icon: <ShieldCheck size={20} />,
    title: 'No Tracking',
    description: '100% private and secure processing.'
  },
];

export default function MediaDownloaderScreen() {
  const [searchParams] = useSearchParams();
  const typeParam = searchParams.get('type') || 'youtube'; // 'youtube' or 'spotify'
  
  const [url, setUrl] = useState('');
  const [downloading, setDownloading] = useState(false);
  const [statusMessage, setStatusMessage] = useState('Fetching & Downloading…');
  const [errorMessage, setErrorMessage] = useState(null);
  const { toast, showToast, dismissToast } = useToast();

  const isYouTube = typeParam === 'youtube';

  // Extract YouTube ID from various URL patterns
  function extractYouTubeId(ytUrl) {
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|shorts\/)([^#&?]*).*/;
    const match = ytUrl.match(regExp);
    return match && match[2].length === 11 ? match[2] : null;
  }

  // Fetch title from oEmbed
  async function fetchMediaTitle(targetUrl) {
    try {
      const res = await fetch(`https://noembed.com/embed?url=${encodeURIComponent(targetUrl)}`);
      if (res.ok) {
        const data = await res.json();
        if (data && data.title) {
          return data.title.replace(/[^\w\s.-]/gi, '').trim();
        }
      }
    } catch (e) {
      console.debug('Failed to fetch media title:', e);
    }
    return null;
  }

  // Multi-instance Cobalt Stream Resolver (for audio/media)
  async function resolveWithCobalt(targetUrl, isAudioOnly = false) {
    const cobaltInstances = [
      'https://cobalt-api.kwiatekm.com',
      'https://cobalt.xy2401.com',
      'https://api.wuk.sh'
    ];

    for (const instance of cobaltInstances) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 7000);
        const res = await fetch(instance, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            url: targetUrl,
            downloadMode: isAudioOnly ? 'audio' : 'auto',
            audioFormat: 'mp3',
            videoQuality: '1080'
          }),
          signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (res.ok) {
          const data = await res.json();
          if (data && (data.url || data.audio || data.status === 'tunnel' || data.status === 'redirect')) {
            return data.url || data.audio;
          }
        }
      } catch (err) {
        console.debug(`Cobalt instance ${instance} unavailable:`, err.message);
      }
    }
    return null;
  }

  // Invidious Stream Resolver for YouTube
  async function resolveWithInvidious(videoId) {
    const invidiousInstances = [
      `https://inv.tux.pizza/api/v1/videos/${videoId}`,
      `https://invidious.jing.rocks/api/v1/videos/${videoId}`,
      `https://vid.puffyan.us/api/v1/videos/${videoId}`,
      `https://iv.ggtyler.dev/api/v1/videos/${videoId}`,
      `https://invidious.projectsegfau.lt/api/v1/videos/${videoId}`
    ];

    for (const endpoint of invidiousInstances) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 6000);
        const res = await fetch(endpoint, { signal: controller.signal });
        clearTimeout(timeoutId);

        if (res.ok) {
          const data = await res.json();
          if (data && data.formatStreams && data.formatStreams.length > 0) {
            const formats = data.formatStreams;
            const chosen = formats.find(f => f.qualityLabel === '720p' || f.quality === 'medium') || formats[0];
            if (chosen && chosen.url) {
              return {
                streamUrl: chosen.url,
                title: data.title || 'youtube_video'
              };
            }
          }
        }
      } catch (err) {
        console.debug(`Invidious instance ${endpoint} unavailable:`, err.message);
      }
    }
    return null;
  }

  // Piped Stream Resolver for YouTube
  async function resolveWithPiped(videoId) {
    const pipedInstances = [
      `https://pipedapi.tokhmi.xyz/streams/${videoId}`,
      `https://api.piped.privacydev.net/streams/${videoId}`,
      `https://pipedapi.kavin.rocks/streams/${videoId}`
    ];

    for (const instance of pipedInstances) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 6000);
        const res = await fetch(instance, { signal: controller.signal });
        clearTimeout(timeoutId);

        if (res.ok) {
          const data = await res.json();
          if (data && data.videoStreams && data.videoStreams.length > 0) {
            const mp4s = data.videoStreams.filter(s => s.mimeType?.includes('mp4') || s.format === 'MPEG_4');
            const stream = mp4s[0] || data.videoStreams[0];
            return {
              streamUrl: stream.url,
              title: data.title || 'youtube_video'
            };
          }
        }
      } catch (err) {
        console.debug(`Piped instance ${instance} unavailable:`, err.message);
      }
    }
    return null;
  }

  async function handleDownload() {
    const trimmed = url.trim();
    if (!trimmed) {
      showToast('Please enter a valid URL', 'error');
      return;
    }
    
    setDownloading(true);
    setErrorMessage(null);
    setStatusMessage('Connecting to media engine…');

    try {
      let downloadBlob = null;
      let downloadFilename = isYouTube ? 'youtube_video.mp4' : 'spotify_track.mp3';
      let downloadMime = isYouTube ? 'video/mp4' : 'audio/mpeg';

      // ── Stage 1: Try Primary Backend API (Local / Render) ──
      try {
        const { API_BASE, REMOTE_API_BASE } = await import('../../services/api');
        const apiTargets = [API_BASE];
        if (REMOTE_API_BASE && REMOTE_API_BASE !== API_BASE) {
          apiTargets.push(REMOTE_API_BASE);
        }

        for (const targetBase of apiTargets) {
          try {
            setStatusMessage('Processing media on server engine… (this may take 20–40s for HD video)');
            const endpoint = isYouTube 
              ? `${targetBase}/api/media/download-youtube` 
              : `${targetBase}/api/media/download-spotify`;
              
            const controller = new AbortController();
            // 120s timeout to allow Render cold-start + yt-dlp download & merge
            const timeoutId = setTimeout(() => controller.abort(), 120000);
            const response = await fetch(endpoint, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ url: trimmed }),
              signal: controller.signal
            });
            clearTimeout(timeoutId);
            
            if (response.ok) {
              const contentDisposition = response.headers.get('content-disposition');
              if (contentDisposition) {
                const match = contentDisposition.match(/filename="?([^"]+)"?/);
                if (match) downloadFilename = match[1];
              }
              downloadBlob = await response.blob();
              if (downloadBlob) break;
            } else {
              const errorText = await response.text();
              console.warn(`Backend returned ${response.status}:`, errorText);
            }
          } catch (targetErr) {
            console.debug(`Backend target ${targetBase} error:`, targetErr.message);
          }
        }
      } catch (backendErr) {
        console.debug('Backend download endpoint error, falling back to stream resolvers:', backendErr.message);
      }

      // ── Stage 2: Direct Stream Resolvers (Invidious / Piped) for YouTube ──
      if (!downloadBlob && isYouTube) {
        setStatusMessage('Extracting direct HD video stream…');
        const ytId = extractYouTubeId(trimmed);
        if (ytId) {
          const invidiousData = await resolveWithInvidious(ytId);
          if (invidiousData && invidiousData.streamUrl) {
            try {
              const streamRes = await fetch(invidiousData.streamUrl);
              if (streamRes.ok) {
                downloadBlob = await streamRes.blob();
                downloadFilename = `${invidiousData.title.replace(/[^\w\s.-]/gi, '').trim() || 'youtube_video'}.mp4`;
              }
            } catch (err) {
              console.debug('Invidious stream fetch error:', err);
            }
          }
          
          if (!downloadBlob) {
            const pipedData = await resolveWithPiped(ytId);
            if (pipedData && pipedData.streamUrl) {
              try {
                const streamRes = await fetch(pipedData.streamUrl);
                if (streamRes.ok) {
                  downloadBlob = await streamRes.blob();
                  downloadFilename = `${pipedData.title.replace(/[^\w\s.-]/gi, '').trim() || 'youtube_video'}.mp4`;
                }
              } catch (err) {
                console.debug('Piped stream fetch error:', err);
              }
            }
          }
        }
      }

      // ── Stage 3: Cobalt Stream Engine Fallback for Spotify / Audio ──
      if (!downloadBlob && !isYouTube) {
        setStatusMessage('Resolving audio stream from cobalt network…');
        const resolvedDirectUrl = await resolveWithCobalt(trimmed, true);
        
        if (resolvedDirectUrl) {
          try {
            const streamRes = await fetch(resolvedDirectUrl);
            if (streamRes.ok) {
              downloadBlob = await streamRes.blob();
              const mediaTitle = await fetchMediaTitle(trimmed);
              if (mediaTitle) {
                downloadFilename = `${mediaTitle}.mp3`;
              }
            }
          } catch (err) {
            console.debug('Cobalt stream fetch error:', err);
          }
        }
      }

      // ── Stage 4: Trigger In-App Delivery ──
      if (downloadBlob) {
        setStatusMessage('Saving file to your device…');
        const objectUrl = URL.createObjectURL(downloadBlob);
        await downloadAndOpenFile(objectUrl, downloadFilename, downloadMime);
        showToast('Download started successfully!', 'success');
        setUrl('');
      } else {
        throw new Error(
          isYouTube 
            ? 'Unable to extract video stream. The video may be age-restricted, copyrighted, or private. Please verify the link and try again.'
            : 'Unable to extract audio track. Please ensure the Spotify track URL is valid and public.'
        );
      }
      
    } catch (err) {
      console.error('Media download error:', err);
      const friendlyMsg = err.message || 'Failed to download media. Please check your connection and link.';
      setErrorMessage(friendlyMsg);
      showToast(friendlyMsg, 'error');
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="ai-screen">

      <div className="ai-screen__unavailable" style={{ opacity: 1, padding: '24px 0', border: 'none', background: 'transparent' }}>
        <div className="ai-screen__unavailable-icon" style={{ background: isYouTube ? 'rgba(239, 68, 68, 0.1)' : 'rgba(34, 197, 94, 0.1)' }}>
          {isYouTube ? (
            <Video size={28} color="#EF4444" />
          ) : (
            <Music size={28} color="#22C55E" />
          )}
        </div>
        <p className="ai-screen__unavailable-title">
          {isYouTube ? 'YouTube Video Downloader' : 'Spotify Audio Downloader'}
        </p>
        <p className="ai-screen__unavailable-sub">
          {isYouTube 
            ? 'Paste a YouTube link below to download the highest quality MP4 video directly to your device.' 
            : 'Paste a Spotify track link below to download it as an MP3 audio file directly to your device.'}
        </p>
      </div>

      <div style={{ marginBottom: '14px' }}>
        <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
          {isYouTube ? 'YouTube URL' : 'Spotify Track URL'}
        </label>
        <input 
          type="url" 
          value={url}
          onChange={(e) => {
            setUrl(e.target.value);
            if (errorMessage) setErrorMessage(null);
          }}
          placeholder={isYouTube ? "https://www.youtube.com/watch?v=..." : "https://open.spotify.com/track/..."}
          style={{ 
            width: '100%', padding: '10px 12px', borderRadius: '10px', 
            border: '1px solid var(--color-divider)',
            background: 'var(--color-surface)', color: 'var(--color-text)',
            fontSize: '13px', outline: 'none'
          }}
          disabled={downloading}
        />
      </div>

      {errorMessage && (
        <div style={{
          display: 'flex',
          alignItems: 'flex-start',
          gap: '10px',
          padding: '12px 14px',
          borderRadius: '10px',
          background: 'rgba(239, 68, 68, 0.1)',
          border: '1px solid rgba(239, 68, 68, 0.25)',
          color: '#DC2626',
          fontSize: '12.5px',
          marginBottom: '14px',
          lineHeight: '1.4'
        }}>
          <AlertCircle size={18} style={{ flexShrink: 0, marginTop: '2px' }} />
          <div style={{ flex: 1 }}>
            <strong>Download Failed</strong>
            <p style={{ margin: '4px 0 0 0', color: '#B91C1C' }}>{errorMessage}</p>
          </div>
        </div>
      )}

      <div className="ai-screen__submit-area">
        <button
          className="ai-screen__submit-btn"
          onClick={handleDownload}
          disabled={!url || downloading}
          style={{ background: isYouTube ? '#EF4444' : '#22C55E', color: '#fff', border: 'none' }}
        >
          {downloading ? (
            <>
              <span className="ai-screen__submit-spinner" />
              Processing & Downloading…
            </>
          ) : (
            <>
              {errorMessage ? <RefreshCw size={17} /> : <Download size={17} />}
              {errorMessage ? 'Try Again' : 'Download Now'}
            </>
          )}
        </button>
      </div>

      {downloading && (
        <div className="ai-screen__loading" style={{ marginTop: '20px' }}>
          <div className="ai-screen__loading-orb" style={{ background: isYouTube ? '#EF4444' : '#22C55E' }}>
            <Download size={26} color="#fff" />
          </div>
          <p className="ai-screen__loading-text">{statusMessage}</p>
          <p className="ai-screen__loading-sub">Connecting to fast media streaming network</p>
        </div>
      )}

      <FeatureTipsSwipeStack tips={TOOL_TIPS} />
      <Toast key={toast?.key} message={toast?.message} type={toast?.type} onDismiss={dismissToast} />
    </div>
  );
}
