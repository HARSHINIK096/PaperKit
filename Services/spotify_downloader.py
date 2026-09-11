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
    Locates ffmpeg binary in the local bin/ folder, system PATH, or common Linux/Render paths.
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

def resolve_youtube_url_for_query(search_query: str) -> Optional[str]:
    """
    Resolves a direct YouTube video URL for a given search query using clean search extraction.
    """
    import yt_dlp
    
    queries = [
        f"ytsearch5:{search_query}",
        f"ytsearch5:{search_query} audio",
        f"ytsearch5:{search_query} official",
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
    
    proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")
    if proxy_url:
        search_opts["proxy"] = proxy_url

    for q in queries:
        try:
            with yt_dlp.YoutubeDL(search_opts) as ydl:
                info = ydl.extract_info(q, download=False)
                if info and "entries" in info and info["entries"]:
                    for entry in info["entries"]:
                        if entry and entry.get("id"):
                            vid_id = entry["id"]
                            print(f"Resolved YouTube video for '{search_query}': https://www.youtube.com/watch?v={vid_id} ({entry.get('title', '')})")
                            return f"https://www.youtube.com/watch?v={vid_id}"
        except Exception as e:
            print(f"Search query '{q}' note: {e}")
            continue

    return None

def download_via_ytdlp(search_query: str, output_dir: str, job_id: Optional[str] = None) -> str:
    """
    Downloads audio stream using yt-dlp and converts to standard 192kbps MP3.
    """
    import yt_dlp
    
    prefix = f"{job_id}_" if job_id else ""
    out_tmpl = os.path.join(output_dir, f"{prefix}%(title)s.%(ext)s")
    ffmpeg_bin = find_ffmpeg_path()
    
    target_video_url = resolve_youtube_url_for_query(search_query)
    download_targets = [target_video_url] if target_video_url else [f"ytsearch1:{search_query}"]
    
    cookie_file = os.getenv("YOUTUBE_COOKIES_FILE") or os.getenv("COOKIES_FILE")
    cookie_content = os.getenv("YOUTUBE_COOKIES")
    cookie_b64 = os.getenv("YOUTUBE_COOKIES_BASE64")

    if not cookie_file and cookie_b64:
        import base64
        try:
            cookie_content = base64.b64decode(cookie_b64.strip()).decode("utf-8")
        except Exception as be:
            print(f"Warning: Failed to decode YOUTUBE_COOKIES_BASE64 in Spotify downloader: {be}")

    if not cookie_file and cookie_content:
        cookie_file = os.path.join(output_dir, f"yt_cookies_{job_id or 'default'}.txt")
        try:
            with open(cookie_file, "w", encoding="utf-8") as f:
                f.write(cookie_content)
        except Exception:
            cookie_file = None

    proxy_url = os.getenv("YTDL_PROXY") or os.getenv("HTTP_PROXY") or os.getenv("HTTPS_PROXY")

    client_strategies = [
        None,
        ["web", "android"],
        ["ios", "mweb"],
        ["tv_embedded", "ios"],
        ["mweb", "android_vr"],
    ]

    last_error = None
    for target in download_targets:
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
            if cookie_file and os.path.exists(cookie_file):
                ydl_opts["cookiefile"] = cookie_file
            if clients:
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
                print(f"yt-dlp download attempt failed with clients {clients}: {e}. Retrying with next client...")
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
        and not f.endswith(".txt")
    ]
    
    if matching_files:
        mp3s = [f for f in matching_files if f.endswith(".mp3")]
        if mp3s:
            return max(mp3s, key=os.path.getctime)
        return max(matching_files, key=os.path.getctime)
        
    raise RuntimeError(f"Download completed but output audio file was not found. Last error: {last_error}")

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
    
    downloaded_file = download_via_ytdlp(search_query, output_dir, job_id=job_id)
    print(f"\nSuccessfully downloaded track: {downloaded_file}")
    return downloaded_file

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PaperKit Spotify Media Downloader CLI")
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
