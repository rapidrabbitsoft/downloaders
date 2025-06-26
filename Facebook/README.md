# Facebook Video Downloader

This directory contains scripts to download Facebook videos and reels from a list of URLs or command-line arguments.

## Files

- `downloads.sh` - Main script to download videos with command-line options
- `downloads.txt` - List of Facebook video/reel URLs to download
- `Downloads/` - Directory where downloaded videos are saved
- `download.sh` - Legacy script (empty)

## Prerequisites

- `yt-dlp` - Video downloader tool
  - Install via: `pip3 install -U yt-dlp` or `brew install yt-dlp`

## Usage

### Basic Usage (from downloads.txt)
```bash
./downloads.sh
```

### Command-line Options
```bash
./downloads.sh [OPTIONS]

Options:
  -u, --urls           Comma-separated list of Facebook URLs
  -d, --dir            Download directory (default: Downloads)
  -r, --retries        Number of retry attempts (default: 3)
  -f, --list-formats   List available formats without downloading
  -h, --help           Display help message
```

### Examples

Download from downloads.txt:
```bash
./downloads.sh
```

Download specific URLs:
```bash
./downloads.sh -u "https://www.facebook.com/reel/123456,https://www.facebook.com/videos/789012"
```

Download to custom directory:
```bash
./downloads.sh -d "MyVideos"
```

List available formats:
```bash
./downloads.sh -f
```

Download with more retries:
```bash
./downloads.sh -r 5
```

## Features

- **Command-line interface**: Flexible options for URLs, directory, and retries
- **Automatic link detection**: Identifies Facebook video and reel URLs
- **Batch downloading**: Downloads all videos in the list
- **Retry mechanism**: Automatically retries failed downloads
- **Format selection**: Automatically selects best available quality
- **Error handling**: Continues downloading even if some videos fail
- **Progress tracking**: Shows download progress and summary
- **Failed URL management**: Saves failed URLs back to downloads.txt
- **Organized output**: Files are saved with descriptive names

## URL Formats Supported

- `https://www.facebook.com/username/videos/video_id/`
- `https://www.facebook.com/reel/reel_id/`
- URLs with query parameters are also supported

## Output

Videos are saved to the `Downloads/` folder (or custom directory) with the format:
`%(title)s.%(ext)s`

## Example Output

```bash
$ ./downloads.sh
[2024-01-15 10:30:15] [INFO] Starting to download 10 Facebook videos
[2024-01-15 10:30:16] [INFO] Downloading: https://www.facebook.com/reel/123456
[2024-01-15 10:30:16] [INFO] Selected format: best[ext=mp4]
[2024-01-15 10:30:45] [SUCCESS] Downloaded: https://www.facebook.com/reel/123456
...
[2024-01-15 10:35:20] [SUCCESS] All Facebook videos downloaded successfully!
```

## Error Handling

- **Failed downloads**: URLs that fail to download are saved back to `downloads.txt`
- **Non-Facebook URLs**: Automatically skipped with a warning
- **Format issues**: Script retries with different format options
- **Network issues**: Configurable retry mechanism with delays

## Troubleshooting

- **yt-dlp not found**: Install it using `pip3 install -U yt-dlp`
- **Permission denied**: Make sure the script is executable (`chmod +x downloads.sh`)
- **Download failures**: Some videos may be private or region-restricted
- **Empty downloads.txt**: Add Facebook video URLs to the file or use `-u` option

## Notes

- The script automatically filters for Facebook URLs only
- Empty lines and comments (starting with #) are ignored in downloads.txt
- Downloads continue even if individual videos fail
- Failed URLs are automatically saved back to downloads.txt for retry
- All files are saved to the specified download directory
