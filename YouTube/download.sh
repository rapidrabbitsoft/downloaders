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

# Function to check if yt-dlp needs updating
check_and_update_ytdlp() {
    local ytdlp_path="/usr/local/bin/yt-dlp"
    local last_check_file="$HOME/.yt-dlp-last-check"
    local current_date=$(date +%Y-%m-%d)
    local last_check_date=""
    
    # Read last check date if file exists
    if [[ -f "$last_check_file" ]]; then
        last_check_date=$(cat "$last_check_file")
    fi
    
    # Check if we need to update (once per day or if yt-dlp doesn't exist)
    if [[ "$last_check_date" != "$current_date" ]] || [[ ! -f "$ytdlp_path" ]]; then
        log "Checking for yt-dlp updates..." "INFO"
        
        # Download latest yt-dlp
        if curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp -o "$ytdlp_path" 2>/dev/null; then
            chmod a+rx "$ytdlp_path"
            log "yt-dlp updated successfully" "SUCCESS"
        else
            log "Failed to update yt-dlp, using existing version" "WARNING"
        fi
        
        # Update last check date
        echo "$current_date" > "$last_check_file"
    else
        log "yt-dlp is up to date (checked today)" "INFO"
    fi
}

# Check if yt-dlp is installed and update if needed
check_and_update_ytdlp

if ! command -v yt-dlp &> /dev/null; then
    log "yt-dlp is not installed" "ERROR"
    log "Please install it using: pip3 install -U yt-dlp" "INFO"
    exit 1
fi

# Check if ffmpeg is installed (needed for best quality merging)
if ! command -v ffmpeg &> /dev/null; then
    log "ffmpeg is not installed - will use fallback merging" "WARNING"
    log "For best quality, install ffmpeg: brew install ffmpeg" "INFO"
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
    fi
fi

# Ensure that we have a valid list of URLs
if [[ ${#URLS[@]} -eq 0 ]]; then
    log "No downloads found, skipping..." "INFO"
    exit 0
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
    
    if [[ -z "$formats" ]]; then
        log "Could not retrieve formats for: $url" "ERROR"
        return 1
    fi

    # Check if this is a DRM protected video (only storyboard images available)
    if echo "$formats" | grep -q "storyboard" && ! echo "$formats" | grep -q "video only\|audio only"; then
        log "This video appears to be DRM protected or unavailable" "ERROR"
        return 1
    fi

    # For YouTube, use the bestvideo+bestaudio format selection for highest quality
    # This ensures we get the best video and best audio separately, then merge them
    echo "bestvideo+bestaudio/best"
}


# Function to strip emojis and clean filename
clean_filename() {
    local filename="$1"
    # Remove emojis and other non-ASCII characters, keep only alphanumeric, spaces, hyphens, underscores
    echo "$filename" | sed 's/[^a-zA-Z0-9 -_]//g' | sed 's/  */ /g' | sed 's/^ *//g' | sed 's/ *$//g'
}

# Function to fetch video title and generate safe filename
generate_filename() {
    local url="$1"
    local video_id=""
    
    # Extract video ID using portable methods (compatible with macOS/BSD grep)
    if echo "$url" | grep -q "youtube\.com/watch"; then
        video_id=$(echo "$url" | sed 's/.*[?&]v=\([^&]*\).*/\1/')
    elif echo "$url" | grep -q "youtu\.be/"; then
        video_id=$(echo "$url" | sed 's/.*youtu\.be\/\([^?&]*\).*/\1/')
    elif echo "$url" | grep -q "youtube\.com/embed/"; then
        video_id=$(echo "$url" | sed 's/.*youtube\.com\/embed\/\([^?&]*\).*/\1/')
    fi
    
    # Try to get the video title
    local title=""
    if command -v yt-dlp &> /dev/null; then
        title=$(yt-dlp --get-title --no-warnings "$url" 2>/dev/null | head -1)
    fi
    
    if [[ -n "$title" && "$title" != "NA" ]]; then
        # Clean the title and use it
        local clean_title=$(clean_filename "$title")
        if [[ -n "$clean_title" ]]; then
            echo "${clean_title}-${video_id}"
        else
            echo "youtube_${video_id}"
        fi
    else
        # Fallback to hash-based filename
        if [[ -z "$video_id" ]]; then
            video_id=$(echo "$url" | md5 | cut -c1-12)
        fi
        echo "youtube_${video_id}"
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
        
        # Generate a clean filename
        local filename=$(generate_filename "$url")
        log "Generated filename: $filename" "INFO"
        
        # Try multiple download strategies to handle 403 errors
        local download_success=false
        
        # Strategy 1: Standard download with bypass options
        log "Attempting download with bypass options..." "INFO"
        if yt-dlp -f "$format" \
                  --no-playlist \
                  --no-warnings \
                  --progress \
                  --merge-output-format mp4 \
                  --prefer-ffmpeg \
                  --audio-quality 0 \
                  --video-multistreams \
                  --audio-multistreams \
                  --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
                  --referer "https://www.youtube.com/" \
                  --add-header "Accept-Language: en-us,en;q=0.5" \
                  --sleep-requests 1 \
                  --sleep-interval 1 \
                  --max-sleep-interval 3 \
                  --fragment-retries 10 \
                  --retries 10 \
                  "$url" \
                  -o "$DOWNLOAD_DIR/$filename.%(ext)s"; then
            download_success=true
        fi
        
        # Strategy 2: If first attempt failed, try with different format selection
        if [[ "$download_success" == false ]]; then
            log "First attempt failed, trying with 'best' format..." "WARNING"
            if yt-dlp -f "best" \
                      --no-playlist \
                      --no-warnings \
                      --progress \
                      --merge-output-format mp4 \
                      --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
                      --referer "https://www.youtube.com/" \
                      --sleep-requests 2 \
                      --sleep-interval 2 \
                      --max-sleep-interval 5 \
                      --fragment-retries 15 \
                      --retries 15 \
                      "$url" \
                      -o "$DOWNLOAD_DIR/$filename.%(ext)s"; then
                download_success=true
            fi
        fi
        
        if [[ "$download_success" == true ]]; then
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
