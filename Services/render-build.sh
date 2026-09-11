#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting PaperKit Render build process..."

# Upgrade pip
python -m pip install --upgrade pip setuptools wheel

# Install Python dependencies
pip install -r requirements.txt
pip install --upgrade "yt-dlp[default]" bgutil-ytdlp-pot-provider imageio-ffmpeg certifi

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

echo "Build process completed successfully."
