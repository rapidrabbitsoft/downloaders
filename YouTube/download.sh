#!/bin/bash

# YouTube Video Downloader
# Downloads YouTube videos in the best available quality
# Supports both single URLs and bulk downloads from a file

# Color codes for prettifying the output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_YELLOW='\033[0;33m'
CYAN='\033[1;36m'
NC='\033[0m'  # No Color

# Default values
URLS=()
FAILED_URLS=()
DOWNLOAD_DIR="Downloads"
MAX_RETRIES=3
RETRY_DELAY=5
LIST_FORMATS=false

# Log function
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Color codes for log levels
    local color
    case "$level" in
        ERROR)
            color="$RED"
            ;;
        WARNING)
            color="$YELLOW"
            ;;
        SUCCESS)
            color="$GREEN"
            ;;
        INFO)
            color="$CYAN"
            ;;
        *)
            color="$NC"
            ;;
    esac
    
    # Print colored output to terminal
    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Display usage
usage() {
    log "Usage: $0 [-u url1,url2,...] [-d directory] [-r retries] [-f]" "INFO"
    log "Options:" "INFO"
    log "  -u, --urls     Comma-separated list of YouTube URLs" "INFO"
    log "  -d, --dir      Download directory (default: Downloads)" "INFO"
    log "  -r, --retries  Number of retry attempts (default: 3)" "INFO"
    log "  -f, --list-formats  List available formats without downloading" "INFO"
    log "  -h, --help     Display this help message" "INFO"
    exit 1
}

# Parse flags
while [[ "$1" == -* ]]; do
    case "$1" in
        -u|--urls)
            IFS=',' read -ra URLS <<< "$2"
            shift 2
            ;;
        -d|--dir)
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        -r|--retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        -f|--list-formats)
            LIST_FORMATS=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *) usage ;;
    esac
done

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
    log "yt-dlp is not installed" "ERROR"
    log "Please install it using: pip3 install -U yt-dlp" "INFO"
    exit 1
fi

# If no URLs are provided via flags, check for downloads.txt file
if [[ ${#URLS[@]} -eq 0 ]]; then
    if [[ -f "downloads.txt" ]]; then
        # Read each line from the file into the URLS array
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ -n "$line" ]]; then
                URLS+=("$line")
            fi
        done < "downloads.txt"
    else
        log "No valid URLs supplied for downloading" "ERROR"
        exit 1
    fi
fi

# Ensure that we have a valid list of URLs
if [[ ${#URLS[@]} -eq 0 ]]; then
    log "No valid URLs supplied for downloading" "ERROR"
    exit 1
fi

# If list-formats flag is set, show formats and exit
if [[ "$LIST_FORMATS" == true ]]; then
    log "Listing available formats for ${#URLS[@]} video(s)" "INFO"
    for url in "${URLS[@]}"; do
        log "Formats for: $url" "INFO"
        yt-dlp -F "$url"
    done
    exit 0
fi

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Start downloading
log "Starting to download ${#URLS[@]} videos" "INFO"

# Function to get best available format
get_best_format() {
    local url="$1"
    local formats
    
    # Get available formats
    formats=$(yt-dlp -F "$url" 2>/dev/null)
    
    # Try different format combinations in order of preference
    if echo "$formats" | grep -q "bestvideo\[ext=mp4\]+bestaudio\[ext=m4a\]"; then
        echo "bestvideo[ext=mp4]+bestaudio[ext=m4a]"
    elif echo "$formats" | grep -q "best\[ext=mp4\]"; then
        echo "best[ext=mp4]"
    elif echo "$formats" | grep -q "bestvideo\[ext=webm\]+bestaudio\[ext=webm\]"; then
        echo "bestvideo[ext=webm]+bestaudio[ext=webm]"
    elif echo "$formats" | grep -q "best\[ext=webm\]"; then
        echo "best[ext=webm]"
    else
        echo "best"
    fi
}

# Function to download a single video with retries
download_video() {
    local url="$1"
    local retry_count=0
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        # Get the best available format
        local format
        format=$(get_best_format "$url")
        
        if [[ -z "$format" ]]; then
            log "Could not determine available formats for: $url" "ERROR"
            return 1
        fi
        
        log "Selected format: $format" "INFO"
        
        if yt-dlp -f "$format" \
                  --no-playlist \
                  --no-warnings \
                  --progress \
                  "$url" \
                  -o "$DOWNLOAD_DIR/%(title)s.%(ext)s"; then
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $MAX_RETRIES ]]; then
            log "Retry $retry_count/$MAX_RETRIES in $RETRY_DELAY seconds..." "WARNING"
            sleep $RETRY_DELAY
        fi
    done
    
    return 1
}

# Loop through each URL and download the video
for url in "${URLS[@]}"; do
    log "Downloading: $url" "INFO"
    
    if download_video "$url"; then
        log "Downloaded: $url" "SUCCESS"
    else
        log "Download Failed: $url" "ERROR"
        FAILED_URLS+=("$url")
    fi
done

# Print failed URLs at the end
if [ ${#FAILED_URLS[@]} -ne 0 ]; then
    log "Some downloads failed (downloads.txt updated)" "ERROR"
    rm -f downloads.txt
    for failed_url in "${FAILED_URLS[@]}"; do
        echo "$failed_url"
    done > downloads.txt
    log "Failed downloads have been saved to downloads.txt" "WARNING"
else
    rm -f downloads.txt
    touch downloads.txt
    log "All videos downloaded successfully!" "SUCCESS"
fi
