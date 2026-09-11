#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting MASKERV Render build process..."

# Upgrade pip
python -m pip install --upgrade pip setuptools wheel

# Install Python dependencies
pip install -r requirements.txt
pip install --upgrade "yt-dlp[default]" yt-dlp-ejs bgutil-ytdlp-pot-provider imageio-ffmpeg certifi

# Install POT Server Node dependencies if available
if [ -d "pot_server" ] && [ -f "pot_server/package.json" ]; then
  echo "Installing PO-token provider dependencies..."
  if command -v npm >/dev/null 2>&1; then
    (cd pot_server && npm ci || npm install)
    echo "PO-token provider setup complete."
  else
    echo "Note: npm not found in build container. External POT_PROVIDER_URL can be configured."
  fi
fi

# Create bin directory
mkdir -p bin

# Attempt to download static FFmpeg binary from reliable GitHub release mirror
echo "Downloading FFmpeg binary for Linux..."
curl -sSL -A "Mozilla/5.0" "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" -o ffmpeg.tar.xz || \
curl -sSL -A "Mozilla/5.0" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" -o ffmpeg.tar.xz || true

if [ -f ffmpeg.tar.xz ]; then
  tar -xf ffmpeg.tar.xz 2>/dev/null || true
  find . -maxdepth 3 -type f -name "ffmpeg" -exec cp {} bin/ \; 2>/dev/null || true
  find . -maxdepth 3 -type f -name "ffprobe" -exec cp {} bin/ \; 2>/dev/null || true
  chmod +x bin/ffmpeg bin/ffprobe 2>/dev/null || true
  rm -rf ffmpeg.tar.xz ffmpeg-* 2>/dev/null || true
fi

# Print safe diagnostic version info
echo "Build verification:"
python -c "import yt_dlp.version; print('yt-dlp version:', yt_dlp.version.__version__)"

echo "Build process completed successfully."
