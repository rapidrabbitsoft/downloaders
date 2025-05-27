# YouTube Video Downloader

A powerful script for downloading YouTube videos in the best available quality. Supports both single video downloads and bulk downloads from a list.

## Features

- Downloads videos in the best available quality (MP4)
- Supports both single URLs and bulk downloads
- Automatic format selection (best video + audio)
- Error handling and failed download tracking
- Progress indicators and colored output

## Usage

### Single Video Download
```bash
./download.sh -u "https://www.youtube.com/watch?v=VIDEO_ID"
```

### Multiple Videos Download
```bash
./download.sh -u "url1,url2,url3"
```

### Bulk Download from File
1. Create a `downloads.txt` file
2. Add one URL per line
3. Run the script without arguments:
```bash
./download.sh
```

## Installation Requirements

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install python3 python3-pip ffmpeg
pip3 install -U yt-dlp
```

### CentOS/RHEL/Fedora
```bash
sudo yum/dnf install python3 python3-pip ffmpeg
pip3 install -U yt-dlp
```

### macOS
```bash
brew install ffmpeg yt-dlp
```

### Windows
1. Download and install Python from [python.org](https://python.org)
2. Download ffmpeg from [ffmpeg.org](https://ffmpeg.org)
3. Add both to your system PATH
4. Install yt-dlp: `pip install -U yt-dlp`

### Arch Linux/Manjaro
```bash
sudo pacman -Syu yt-dlp ffmpeg
```

## Notes

- Downloaded videos are saved in the `Downloads` directory
- Failed downloads are automatically tracked and saved to `downloads.txt`
- The script requires an empty line at the end of `downloads.txt`
