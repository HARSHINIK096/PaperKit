import os
import sys
import ssl
import json
import argparse
import subprocess
from typing import Optional, Tuple

# Ensure SSL certificates are properly loaded
try:
    import certifi
    ca_bundle = certifi.where()
    os.environ["SSL_CERT_FILE"] = ca_bundle
    os.environ["REQUESTS_CA_BUNDLE"] = ca_bundle
    os.environ["CURL_CA_BUNDLE"] = ca_bundle
except ImportError:
    ca_bundle = None

def find_ffmpeg_path() -> Optional[str]:
    """
    Locates ffmpeg binary in the local bin/ folder, system PATH, common Linux/Render paths, or imageio-ffmpeg.
    """
    import shutil
    base_dir = os.path.dirname(os.path.abspath(__file__))
    bin_dir = os.path.join(base_dir, "bin")
    
    local_ffmpeg = os.path.join(bin_dir, "ffmpeg.exe" if os.name == "nt" else "ffmpeg")
    if os.path.isfile(local_ffmpeg):
        return local_ffmpeg

    sys_ffmpeg = shutil.which("ffmpeg")
    if sys_ffmpeg and os.path.isfile(sys_ffmpeg):
        return sys_ffmpeg

    for p in ["/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg"]:
        if os.path.isfile(p):
            return p

    try:
        import importlib
        imageio_ffmpeg = importlib.import_module("imageio_ffmpeg")
        ffmpeg_exe = getattr(imageio_ffmpeg, "get_ffmpeg_exe", lambda: None)()
        if ffmpeg_exe and os.path.isfile(ffmpeg_exe):
            return ffmpeg_exe
    except Exception:
        pass
        
    return None

def extract_spotify_metadata(url: str) -> Tuple[str, str]:
    """
    Retrieves track metadata (Title & Artist) using Spotify's official oEmbed API with OpenGraph fallback.
    """
    import urllib.request
    import bs4
    
    clean_url = url.split("?")[0].strip()
    
    ctx = ssl.create_default_context(cafile=ca_bundle) if ca_bundle else ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    title = ""
    artists = ""
    
    # 1. Primary: Official Spotify oEmbed API (fast, structured, no auth required)
    try:
        oembed_url = f"https://open.spotify.com/oembed?url={clean_url}"
        req = urllib.request.Request(
            oembed_url,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        )
        resp = urllib.request.urlopen(req, context=ctx, timeout=8).read().decode("utf-8")
        data = json.loads(resp)
        if data.get("title"):
            title = data["title"].strip()
    except Exception as e:
        print(f"oEmbed fetch note: {e}")
        
    # 2. Extract detailed artists from Spotify Page HTML OpenGraph tags
    try:
        req = urllib.request.Request(
            clean_url,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        )
        html = urllib.request.urlopen(req, context=ctx, timeout=8).read().decode("utf-8")
        soup = bs4.BeautifulSoup(html, "html.parser")
        
        if not title:
            og_title = soup.find("meta", property="og:title")
            if og_title and og_title.get("content"):
                title = og_title["content"].strip()
                
        og_desc = soup.find("meta", property="og:description")
        if og_desc and og_desc.get("content"):
            desc = og_desc["content"].strip()
            artists = desc.split("·")[0].strip() if "·" in desc else desc
            
        if not title and soup.title:
            raw_title = soup.title.string or ""
            title = raw_title.split("|")[0].replace("- song and lyrics by", "").replace("- song by", "").strip()
    except Exception as e:
        print(f"OpenGraph scrape note: {e}")
        
    return title or "Spotify Track", artists

def format_netscape_cookies(raw_content: str) -> str:
    """
    Ensures every entry in a Netscape cookies text file strictly satisfies the 7 tab-separated columns specification.
    """
    formatted_lines = []
    for line in raw_content.splitlines():
        trimmed = line.strip()
        if not trimmed or trimmed.startswith("#"):
            formatted_lines.append(line)
            continue
        parts = line.split("\t")
        if len(parts) == 5:
            domain, sub, exp, name, val = parts
            formatted_lines.append(f"{domain}\t{sub}\t/\tTRUE\t{exp}\t{name}\t{val}")
        elif len(parts) == 6:
            domain, sub, path, exp, name, val = parts
            formatted_lines.append(f"{domain}\t{sub}\t{path}\tTRUE\t{exp}\t{name}\t{val}")
        else:
            formatted_lines.append(line)
    return "\n".join(formatted_lines) + "\n"

def get_or_create_cookie_file(output_dir: str = ".", job_id: Optional[str] = None) -> Optional[str]:
    """
    Extracts and returns the path to a valid YouTube Netscape cookies file from env vars.
    """
    cookie_file = os.getenv("YOUTUBE_COOKIES_FILE") or os.getenv("COOKIES_FILE")
    if cookie_file and os.path.isfile(cookie_file):
        return cookie_file

    cookie_content = os.getenv("YOUTUBE_COOKIES")
    cookie_b64 = os.getenv("YOUTUBE_COOKIES_BASE64")

    if not cookie_content and cookie_b64:
        import base64
        try:
            cookie_content = base64.b64decode(cookie_b64.strip()).decode("utf-8", errors="ignore")
        except Exception as be:
            print(f"Warning: Failed to decode YOUTUBE_COOKIES_BASE64 in Spotify downloader: {be}")

    if cookie_content:
        os.makedirs(output_dir, exist_ok=True)
        cookie_path = os.path.join(output_dir, f"yt_cookies_{job_id or 'global'}.txt")
        try:
            sanitized = format_netscape_cookies(cookie_content)
            with open(cookie_path, "w", encoding="utf-8") as f:
                f.write(sanitized)
            return cookie_path
        except Exception as ce:
            print(f"Warning: Could not write cookie file: {ce}")

    return None

def resolve_audio_sources_for_query(search_query: str, cookie_file: Optional[str] = None) -> list:
    """
    Resolves a list of candidate audio stream URLs across YouTube, YouTube Music, and SoundCloud.
    """
    import yt_dlp
    
    queries = [
        f"ytsearch5:{search_query}",
        f"ytsearch5:{search_query} audio",
        f"ytsearch5:{search_query} official",
        f"scsearch5:{search_query}",  # SoundCloud fallback (never blocks cloud/Render IPs)
    ]
    
    search_opts = {
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "extract_flat": True,
        "skip_download": True,
        "default_search": "ytsearch",
        "http_headers": {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9",
        }
    }
    
    if cookie_file and os.path.exists(cookie_file):
        search_opts["cookiefile"] = cookie_file

    proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")
    if proxy_url:
        search_opts["proxy"] = proxy_url

    sources = []
    seen = set()

    for q in queries:
        try:
            with yt_dlp.YoutubeDL(search_opts) as ydl:
                info = ydl.extract_info(q, download=False)
                if info and "entries" in info and info["entries"]:
                    for entry in info["entries"]:
                        if not entry:
                            continue
                        url = entry.get("webpage_url") or entry.get("url")
                        vid_id = entry.get("id")
                        target = None
                        if url and ("youtube.com" in url or "soundcloud.com" in url or "youtu.be" in url):
                            target = url
                        elif vid_id and not vid_id.startswith("http"):
                            target = f"https://www.youtube.com/watch?v={vid_id}"
                        
                        if target and target not in seen:
                            seen.add(target)
                            sources.append(target)
                            print(f"Candidate audio source found: {target} ({entry.get('title', '')})")
        except Exception as e:
            print(f"Search provider '{q}' note: {e}")
            continue

    # Append direct search fallbacks as last resort
    if f"scsearch1:{search_query}" not in seen:
        sources.append(f"scsearch1:{search_query}")
    if f"ytsearch1:{search_query}" not in seen:
        sources.append(f"ytsearch1:{search_query}")

    return sources

def resolve_audio_stream_url_for_query(search_query: str) -> Optional[str]:
    """
    Backwards-compatible helper returning the top resolved stream source.
    """
    sources = resolve_audio_sources_for_query(search_query)
    return sources[0] if sources else None

def download_via_ytdlp(search_query: str, output_dir: str, job_id: Optional[str] = None) -> str:
    """
    Downloads audio stream using yt-dlp across multiple candidate sources and converts to standard 192kbps MP3.
    """
    import yt_dlp
    
    prefix = f"{job_id}_" if job_id else ""
    out_tmpl = os.path.join(output_dir, f"{prefix}%(title)s.%(ext)s")
    ffmpeg_bin = find_ffmpeg_path()
    
    cookie_file = get_or_create_cookie_file(output_dir, job_id)
    download_targets = resolve_audio_sources_for_query(search_query, cookie_file=cookie_file)
    if not download_targets:
        download_targets = [f"ytsearch1:{search_query}", f"scsearch1:{search_query}"]

    proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")

    # If cookies are provided, standard player client (None or web) should be used
    if cookie_file and os.path.exists(cookie_file):
        yt_client_strategies = [None, ["web"], ["mweb"]]
    else:
        yt_client_strategies = [
            None,
            ["web", "android"],
            ["ios", "mweb"],
            ["tv_embedded", "ios"],
            ["mweb", "android_vr"],
        ]

    last_error = None
    for target in download_targets:
        is_soundcloud = "soundcloud.com" in target or target.startswith("scsearch")
        client_strategies = [None] if is_soundcloud else yt_client_strategies

        for clients in client_strategies:
            ydl_opts = {
                "outtmpl": out_tmpl,
                "format": "bestaudio/best",
                "quiet": False,
                "no_warnings": True,
                "nocheckcertificate": True,
                "ignoreerrors": False,
                "http_headers": {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                    "Accept-Language": "en-US,en;q=0.9",
                }
            }
            if ffmpeg_bin:
                ydl_opts["ffmpeg_location"] = os.path.dirname(ffmpeg_bin) if os.path.isfile(ffmpeg_bin) else ffmpeg_bin
                ydl_opts["postprocessors"] = [{
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "mp3",
                    "preferredquality": "192",
                }]
            if proxy_url:
                ydl_opts["proxy"] = proxy_url
            if cookie_file and os.path.exists(cookie_file) and not is_soundcloud:
                ydl_opts["cookiefile"] = cookie_file
            if clients and not is_soundcloud:
                ydl_opts["extractor_args"] = {
                    "youtube": {
                        "player_client": clients,
                    }
                }

            print(f"Downloading audio from {target} (clients: {clients})...")
            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    ydl.download([target])
                
                # Check if audio was produced
                matching_files = [
                    os.path.join(output_dir, f)
                    for f in os.listdir(output_dir)
                    if os.path.isfile(os.path.join(output_dir, f))
                    and os.path.getsize(os.path.join(output_dir, f)) > 1024
                    and (not job_id or f.startswith(job_id))
                    and not f.endswith(".part")
                    and not f.endswith(".ytdl")
                    and not f.endswith(".txt")
                ]
                if matching_files:
                    mp3s = [f for f in matching_files if f.endswith(".mp3")]
                    if mp3s:
                        return max(mp3s, key=os.path.getctime)
                    return max(matching_files, key=os.path.getctime)
            except Exception as e:
                last_error = e
                print(f"yt-dlp attempt failed for {target} (clients: {clients}): {e}. Trying next...")
                if "Sign in to confirm" in str(e) or "bot" in str(e).lower():
                    print(f"YouTube bot detection encountered for {target}. Moving to next source candidate...")
                    break
                continue

    # Locate output file
    matching_files = [
        os.path.join(output_dir, f)
        for f in os.listdir(output_dir)
        if os.path.isfile(os.path.join(output_dir, f))
        and os.path.getsize(os.path.join(output_dir, f)) > 1024
        and (not job_id or f.startswith(job_id))
        and not f.endswith(".part")
        and not f.endswith(".ytdl")
    ]
    if matching_files:
        mp3s = [f for f in matching_files if f.endswith(".mp3")]
        if mp3s:
            return max(mp3s, key=os.path.getctime)
        return max(matching_files, key=os.path.getctime)
        
    raise RuntimeError(f"Download completed but output audio file was not found. Last error: {last_error}")

def download_via_spotdl_fallback(url: str, output_dir: str, job_id: Optional[str] = None) -> Optional[str]:
    """
    Tertiary fallback using spotdl CLI subprocess if available.
    """
    import subprocess
    prefix = f"{job_id}_" if job_id else ""
    cookie_file = get_or_create_cookie_file(output_dir, job_id)
    try:
        cmd = [
            sys.executable, "-m", "spotdl",
            "download", url,
            "--output", os.path.join(output_dir, f"{prefix}{{title}} - {{artists}}.{{output-ext}}"),
            "--format", "mp3",
            "--bitrate", "192k",
            "--threads", "1",
        ]
        if cookie_file and os.path.isfile(cookie_file):
            cmd.extend(["--cookie-file", cookie_file])
            
        ffmpeg_bin = find_ffmpeg_path()
        if ffmpeg_bin:
            cmd.extend(["--ffmpeg", ffmpeg_bin])

        print(f"Attempting spotdl fallback execution: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        print(f"spotdl result code: {result.returncode}")
        
        matching_files = [
            os.path.join(output_dir, f)
            for f in os.listdir(output_dir)
            if os.path.isfile(os.path.join(output_dir, f))
            and os.path.getsize(os.path.join(output_dir, f)) > 1024
            and (not job_id or f.startswith(job_id))
            and f.endswith(".mp3")
        ]
        if matching_files:
            return max(matching_files, key=os.path.getctime)
    except Exception as e:
        print(f"spotdl fallback exception: {e}")
    return None

def download_spotify_track(url: str, output_dir: str = ".", output_template: Optional[str] = None, job_id: Optional[str] = None) -> str:
    """
    Downloads Spotify track audio as MP3 along with metadata.
    """
    if not url or not url.strip():
        raise ValueError("A valid Spotify URL must be provided.")
    
    url = url.strip()
    if "spotify.com" not in url and "spotify:" not in url:
        raise ValueError("Invalid Spotify URL. URL must contain 'spotify.com' or 'spotify:'.")
        
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Resolving Spotify track: {url}")
    title, artists = extract_spotify_metadata(url)
    search_query = f"{artists} {title}".strip() if artists and title != artists else title
    print(f"Identified Track: '{title}' by '{artists}'")
    print(f"Search Query: '{search_query}'")
    
    try:
        downloaded_file = download_via_ytdlp(search_query, output_dir, job_id=job_id)
        print(f"\nSuccessfully downloaded track: {downloaded_file}")
        return downloaded_file
    except Exception as err:
        print(f"Primary multi-provider downloader note: {err}. Checking spotdl fallback...")
        spotdl_file = download_via_spotdl_fallback(url, output_dir, job_id=job_id)
        if spotdl_file:
            print(f"\nSuccessfully downloaded track via spotdl: {spotdl_file}")
            return spotdl_file
        raise err

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MASKERV Spotify Media Downloader CLI")
    parser.add_argument("url", nargs="?", help="Spotify track, album, or playlist URL")
    parser.add_argument("-o", "--output", default=".", help="Target output directory")
    args = parser.parse_args()
    
    target_url = args.url
    if not target_url:
        try:
            target_url = input("Enter Spotify Track / Album / Playlist URL: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nAborted.")
            sys.exit(0)
            
    if target_url:
        try:
            downloaded = download_spotify_track(target_url, output_dir=args.output)
            print(f"\n[SUCCESS] File ready at: {downloaded}")
        except Exception as err:
            print(f"\n[ERROR] {err}")
            sys.exit(1)
    else:
        print("No URL provided.")
        sys.exit(1)
