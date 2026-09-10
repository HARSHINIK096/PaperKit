import sys
import yt_dlp

def download_youtube_video(url, output_path="."):
    """
    Downloads a YouTube video in the highest available quality using yt-dlp.
    """
    print(f"Downloading video from: {url}")
    ydl_opts = {
        'outtmpl': f'{output_path}/%(title)s.%(ext)s',
        'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        'merge_output_format': 'mp4',
        'js_runtimes': {'node': {}},
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
        }
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            print(f"\nDownload completed successfully: '{info.get('title')}'")
    except Exception as e:
        print(f"\nAn error occurred while downloading: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        video_url = sys.argv[1]
    else:
        video_url = input("Enter the YouTube video URL: ")
    
    if video_url.strip():
        download_youtube_video(video_url.strip())
    else:
        print("No URL provided.")
