#!/bin/bash

# Gab Video Downloader
# Downloads videos from the Gab platform
# Supports both single URLs and bulk downloads from a file

# Color codes
BOLD='\033[1m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# Default values
URLS=()
FAILED_URLS=()
DOWNLOAD_DIR="Downloads"
MAX_RETRIES=3
RETRY_DELAY=5
TEMP_DIR="/tmp/gab_downloader"

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
    log "Usage: $0 [-u url1,url2,...] [-d directory] [-r retries]" "INFO"
    log "Options:" "INFO"
    log "  -u, --urls     Comma-separated list of Gab URLs" "INFO"
    log "  -d, --dir      Download directory (default: Downloads)" "INFO"
    log "  -r, --retries  Number of retry attempts (default: 3)" "INFO"
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
        -h|--help)
            usage
            ;;
        *) usage ;;
    esac
done

# Check if required commands are installed
for cmd in curl wget python3; do
    if ! command -v "$cmd" &> /dev/null; then
        log "$cmd is not installed" "ERROR"
        exit 1
    fi
done

# Check if Python dependencies are installed
if ! pipenv run python -c "import bs4" &> /dev/null; then
    log "BeautifulSoup4 is not installed" "ERROR"
    log "Please install it using: pipenv install" "INFO"
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
    fi
fi

# Ensure that we have a valid list of URLs
if [[ ${#URLS[@]} -eq 0 ]]; then
    log "No downloads found, skipping..." "INFO"
    exit 0
fi

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Function to truncate filename if too long
truncate_filename() {
    local filename="$1"
    local max_length=100
    
    # Get the extension
    local extension=""
    if [[ "$filename" =~ \.([^.]*)$ ]]; then
        extension=".${BASH_REMATCH[1]}"
        filename="${filename%.*}"
    fi
    
    # Truncate the base filename if too long
    if [[ ${#filename} -gt $max_length ]]; then
        filename="${filename:0:$max_length}"
    fi
    
    echo "${filename}${extension}"
}

# Function to download a single video with retries
download_video() {
    local url="$1"
    local retry_count=0
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        # Fetch the HTML content
        if ! curl -s -L "$url" > "$TEMP_DIR/temp.html"; then
            retry_count=$((retry_count + 1))
            continue
        fi
        
        # Extract video URL
        video_url=$(pipenv run python extract.py --file "$TEMP_DIR/temp.html")
        
        if [[ -n "$video_url" ]]; then
            # Extract filename from URL and truncate if too long
            video_filename=$(basename "$video_url")
            video_filename=$(truncate_filename "$video_filename")
            target_path="$DOWNLOAD_DIR/$video_filename"
            
            # Check if file already exists
            if [[ -f "$target_path" ]]; then
                log "File already exists: $target_path" "WARNING"
                return 0
            fi
            
            # Download the video
            if wget -q --show-progress "$video_url" -O "$target_path"; then
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $MAX_RETRIES ]]; then
            log "Retry $retry_count/$MAX_RETRIES in $RETRY_DELAY seconds..." "WARNING"
            sleep $RETRY_DELAY
        fi
    done
    
    return 1
}

# Start downloading
log "Starting to download ${#URLS[@]} videos" "INFO"

# Loop through each URL
for url in "${URLS[@]}"; do
    log "Processing: $url" "INFO"
    
    if download_video "$url"; then
        log "Downloaded: $url" "SUCCESS"
    else
        log "Download Failed: $url" "ERROR"
        FAILED_URLS+=("$url")
    fi
done

# Clean up temporary files
rm -rf "$TEMP_DIR"

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
