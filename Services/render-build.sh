#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting PaperKit Render build process..."

# Upgrade pip
python -m pip install --upgrade pip setuptools wheel

# Install Python dependencies
pip install -r requirements.txt
pip install --upgrade "yt-dlp[default]"

# Create bin directory
mkdir -p bin

# Attempt to download static FFmpeg binary (non-blocking if download server is temporarily unavailable)
echo "Downloading FFmpeg static binary..."
curl -sSL -A "Mozilla/5.0" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" -o ffmpeg.tar.xz || wget -q -U "Mozilla/5.0" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" -O ffmpeg.tar.xz || true

if [ -f ffmpeg.tar.xz ]; then
  tar -xf ffmpeg.tar.xz 2>/dev/null || true
  cp ffmpeg-*-static/ffmpeg bin/ 2>/dev/null || true
  cp ffmpeg-*-static/ffprobe bin/ 2>/dev/null || true
  chmod +x bin/ffmpeg bin/ffprobe 2>/dev/null || true
  rm -rf ffmpeg.tar.xz ffmpeg-*-static 2>/dev/null || true
fi

echo "Build process completed successfully."
