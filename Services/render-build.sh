#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting MASKERV Render build process..."

# Create bin directory
mkdir -p bin
export PATH="$(pwd)/bin:$PATH"

# Install Node.js LTS if node is not found in PATH
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found in PATH. Downloading standalone Node.js LTS for Linux..."
  NODE_VERSION="v20.18.0"
  NODE_DIST="node-${NODE_VERSION}-linux-x64"
  curl -sSL "https://nodejs.org/dist/${NODE_VERSION}/${NODE_DIST}.tar.xz" -o node.tar.xz
  mkdir -p node_tmp
  tar -xf node.tar.xz -C node_tmp --strip-components=1
  cp -rf node_tmp/bin/* bin/ 2>/dev/null || true
  cp -rf node_tmp/lib bin/ 2>/dev/null || true
  rm -rf node.tar.xz node_tmp
  echo "Node.js installation complete: $(bin/node -v 2>/dev/null || echo 'installed')"
else
  echo "Node.js found in system PATH: $(node -v)"
fi

# Upgrade pip
python -m pip install --upgrade pip setuptools wheel

# Install Python dependencies
pip install -r requirements.txt
pip install --upgrade "yt-dlp[default]" yt-dlp-ejs bgutil-ytdlp-pot-provider imageio-ffmpeg certifi

# Install POT Server Node dependencies if available
if [ -d "pot_server" ] && [ -f "pot_server/package.json" ]; then
  echo "Installing PO-token provider dependencies..."
  if command -v npm >/dev/null 2>&1 || [ -f "bin/npm" ]; then
    (cd pot_server && (npm ci || npm install || ../bin/npm install))
    echo "PO-token provider setup complete."
  else
    echo "Warning: npm not found. Local PO-token server dependencies could not be installed."
  fi
fi

# Attempt to download static FFmpeg binary from reliable GitHub release mirror
echo "Downloading FFmpeg binary for Linux..."
curl -sSL -A "Mozilla/5.0" "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" -o ffmpeg.tar.xz || \
curl -sSL -A "Mozilla/5.0" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" -o ffmpeg.tar.xz || true

if [ -f ffmpeg.tar.xz ]; then
  tar -xf ffmpeg.tar.xz 2>/dev/null || true
  find . -maxdepth 3 -type f -name "ffmpeg" -exec cp {} bin/ \; 2>/dev/null || true
  find . -maxdepth 3 -type f -name "ffprobe" -exec cp {} bin/ \; 2>/dev/null || true
  chmod +x bin/ffmpeg bin/ffprobe bin/node bin/npm 2>/dev/null || true
  rm -rf ffmpeg.tar.xz ffmpeg-* 2>/dev/null || true
fi

# Print safe diagnostic version info
echo "Build verification:"
python -c "import yt_dlp.version; print('yt-dlp version:', yt_dlp.version.__version__)"
if command -v node >/dev/null 2>&1 || [ -f "bin/node" ]; then
  node_ver=$(node -v 2>/dev/null || bin/node -v 2>/dev/null || echo "unknown")
  echo "Node.js available: $node_ver"
fi

echo "Build process completed successfully."

