# Downloaders

A collection of bulk downloaders for various platforms.

## Available Downloaders

### YouTube Video Downloader
- Downloads YouTube videos in the highest available quality (best video + best audio)
- Supports single URLs or bulk downloads via file
- Features automatic format selection and error handling
- Automatically truncates long filenames to prevent "File name too long" errors
- Uses ffmpeg for optimal audio/video merging when available

### Gab Video Downloader
- Downloads videos from Gab platform
- Supports single URLs or bulk downloads via file
- Includes HTML parsing and video extraction
- Automatically truncates long filenames to prevent "File name too long" errors

### Facebook Video Downloader
- Downloads Facebook videos and reels in the best available quality
- Supports single URLs or bulk downloads via file
- Features automatic format selection and error handling
- Automatically truncates long filenames to prevent "File name too long" errors

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/downloaders.git
cd downloaders
```

2. Install dependencies for each downloader:
- For YouTube: See [YouTube/README.md](YouTube/README.md)
- For Gab: See [Gab/README.md](Gab/README.md)
- For Facebook: See [Facebook/README.md](Facebook/README.md)

## Usage

### Master Downloader Script (`download.sh`)

The `download.sh` script is the recommended way to download from multiple platforms. It automatically detects the platform from URLs and routes them to the appropriate downloader.

**Features:**
- Automatic platform detection (YouTube, Facebook, Gab)
- Processes URLs from a master `downloads.txt` file
- Supports mixed URLs from different platforms
- Color-coded logging
- Comprehensive error handling

**Options:**
- `-u, --urls` - Comma-separated list of URLs from any platform
- `-f, --file` - Path to downloads.txt file (default: ./downloads.txt)
- `-h, --help` - Display help message

**Examples:**
```bash
# Download from master downloads.txt file
./download.sh

# Download specific URLs
./download.sh -u "https://youtube.com/watch?v=...,https://facebook.com/watch?v=..."

# Use custom downloads file
./download.sh -f /path/to/my/downloads.txt
```

**Master downloads.txt:**
Create a `downloads.txt` file in the root directory with one URL per line:
```
https://www.youtube.com/watch?v=VIDEO_ID
https://www.facebook.com/videos/VIDEO_ID
https://gab.com/posts/POST_ID
```

### All-in-One Script (`all.sh`)

The `all.sh` script allows you to run all downloaders with prefixed flags for each service.

#### Global Options
- `--youtube-only` - Run only YouTube downloads
- `--gab-only` - Run only Gab downloads
- `--facebook-only` - Run only Facebook downloads
- `--skip-youtube` - Skip YouTube downloads
- `--skip-gab` - Skip Gab downloads
- `--skip-facebook` - Skip Facebook downloads
- `-h, --help` - Display help message

#### YouTube Options (`--youtube-*`)
- `--youtube-urls` - Comma-separated list of YouTube URLs
- `--youtube-dir` - Download directory (default: YouTube/Downloads)
- `--youtube-retries` - Number of retry attempts (default: 3)
- `--youtube-list-formats` - List available formats without downloading

#### Gab Options (`--gab-*`)
- `--gab-urls` - Comma-separated list of Gab URLs
- `--gab-dir` - Download directory (default: Gab/Downloads)
- `--gab-retries` - Number of retry attempts (default: 3)

#### Facebook Options (`--facebook-*`)
- `--facebook-urls` - Comma-separated list of Facebook URLs
- `--facebook-dir` - Download directory (default: Facebook/Downloads)
- `--facebook-retries` - Number of retry attempts (default: 3)
- `--facebook-list-formats` - List available formats without downloading

#### Examples
```bash
# Run all services with custom retries
./all.sh --youtube-retries 5 --gab-retries 3 --facebook-retries 4

# Run only YouTube with specific URLs
./all.sh --youtube-only --youtube-urls "url1,url2,url3"

# Skip Facebook and run others
./all.sh --skip-facebook --youtube-list-formats

# Run with custom directories
./all.sh --youtube-dir "/custom/youtube/path" --gab-dir "/custom/gab/path"
```

### Individual Downloaders

Each downloader can be run independently from its respective directory.

#### YouTube Downloader (`YouTube/download.sh`)

**Options:**
- `-u, --urls` - Comma-separated list of YouTube URLs
- `-d, --dir` - Download directory (default: Downloads)
- `-r, --retries` - Number of retry attempts (default: 3)
- `-f, --list-formats` - List available formats without downloading
- `-h, --help` - Display help message

**Examples:**
```bash
cd YouTube
./download.sh -u "https://youtube.com/watch?v=VIDEO_ID"
./download.sh -r 5 -d "/custom/path"
./download.sh -f  # List formats only
```

#### Gab Downloader (`Gab/download.sh`)

**Options:**
- `-u, --urls` - Comma-separated list of Gab URLs
- `-d, --dir` - Download directory (default: Downloads)
- `-r, --retries` - Number of retry attempts (default: 3)
- `-h, --help` - Display help message

**Examples:**
```bash
cd Gab
./download.sh -u "https://gab.com/video/URL"
./download.sh -r 5 -d "/custom/path"
```

#### Facebook Downloader (`Facebook/downloads.sh`)

**Options:**
- `-u, --urls` - Comma-separated list of Facebook URLs
- `-d, --dir` - Download directory (default: Downloads)
- `-r, --retries` - Number of retry attempts (default: 3)
- `-f, --list-formats` - List available formats without downloading
- `-h, --help` - Display help message

**Examples:**
```bash
cd Facebook
./downloads.sh -u "https://facebook.com/video/URL"
./downloads.sh -r 5 -d "/custom/path"
./downloads.sh -f  # List formats only
```

### Bulk Downloads

There are two ways to do bulk downloads:

1. **Master downloads.txt** (Recommended): Add URLs from all platforms to the root `downloads.txt` file and run `./download.sh`
2. **Platform-specific**: Each downloader supports bulk downloads using a `downloads.txt` file in their respective directories. Simply add one URL per line to the file and run the script without the `-u` flag.

## File Structure

```
Downloaders/
├── download.sh            # Master downloader (recommended)
├── downloads.txt          # Master downloads file
├── all.sh                 # All-in-one downloader script
├── YouTube/
│   ├── download.sh        # YouTube downloader
│   ├── downloads.txt      # Bulk URLs for YouTube
│   └── Downloads/         # YouTube downloads directory
├── Gab/
│   ├── download.sh        # Gab downloader
│   ├── downloads.txt      # Bulk URLs for Gab
│   └── Downloads/         # Gab downloads directory
└── Facebook/
    ├── download.sh        # Facebook downloader
    ├── downloads.txt      # Bulk URLs for Facebook
    └── Downloads/         # Facebook downloads directory
```

## Dependencies

### YouTube Downloader
- `yt-dlp` - Install with: `pip3 install -U yt-dlp`
- `ffmpeg` - Install with: `brew install ffmpeg` (recommended for best quality merging)

### Gab Downloader
- `curl` - Usually pre-installed
- `wget` - Usually pre-installed
- `python3` - Usually pre-installed
- `beautifulsoup4` - Install with: `pip3 install beautifulsoup4`

### Facebook Downloader
- `yt-dlp` - Install with: `pip3 install -U yt-dlp`

## Contributing

Feel free to submit issues and enhancement requests!

