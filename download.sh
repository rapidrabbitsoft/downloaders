#!/bin/bash

# Master Video Downloader
# Routes URLs to the appropriate downloader based on the platform
# Supports bulk downloads from a master downloads.txt file

# Color codes for prettifying the output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'  # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    log "Usage: $0 [-f file] [-u url1,url2,...]" "INFO"
    log "Options:" "INFO"
    log "  -f, --file     Path to downloads.txt file (default: ./downloads.txt)" "INFO"
    log "  -u, --urls     Comma-separated list of URLs" "INFO"
    log "  -h, --help     Display this help message" "INFO"
    log "" "INFO"
    log "Supports:" "INFO"
    log "  - YouTube (youtube.com, youtu.be)" "INFO"
    log "  - Facebook (facebook.com)" "INFO"
    log "  - Gab (gab.com)" "INFO"
    exit 1
}

# Default values
URLS=()
DOWNLOAD_FILE="$SCRIPT_DIR/downloads.txt"

# Parse flags
while [[ "$1" == -* ]]; do
    case "$1" in
        -u|--urls)
            IFS=',' read -ra URLS <<< "$2"
            shift 2
            ;;
        -f|--file)
            DOWNLOAD_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *) usage ;;
    esac
done

# If no URLs provided via flags, read from file
if [[ ${#URLS[@]} -eq 0 ]]; then
    if [[ -f "$DOWNLOAD_FILE" ]]; then
        log "Reading URLs from: $DOWNLOAD_FILE" "INFO"
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                URLS+=("$line")
            fi
        done < "$DOWNLOAD_FILE"
    fi
fi

# Ensure we have URLs to process
if [[ ${#URLS[@]} -eq 0 ]]; then
    log "No URLs found to download" "WARNING"
    exit 0
fi

log "Found ${#URLS[@]} URL(s) to process" "INFO"

# Categorize URLs by platform
YOUTUBE_URLS=()
FACEBOOK_URLS=()
GAB_URLS=()
UNKNOWN_URLS=()

for url in "${URLS[@]}"; do
    if [[ "$url" =~ ^https?://.*(youtube\.com|youtu\.be) ]]; then
        YOUTUBE_URLS+=("$url")
    elif [[ "$url" =~ ^https?://.*facebook\.com ]]; then
        FACEBOOK_URLS+=("$url")
    elif [[ "$url" =~ ^https?://.*gab\.com ]]; then
        GAB_URLS+=("$url")
    else
        UNKNOWN_URLS+=("$url")
    fi
done

# Function to call downloader script
call_downloader() {
    local platform="$1"
    shift
    local urls=("$@")
    
    if [[ ${#urls[@]} -eq 0 ]]; then
        return 0
    fi
    
    local downloader_script="$SCRIPT_DIR/$platform/download.sh"
    
    if [[ ! -f "$downloader_script" ]]; then
        log "Downloader script not found: $downloader_script" "ERROR"
        return 1
    fi
    
    log "Processing ${#urls[@]} $platform URL(s)" "INFO"
    
    # Create a temporary file with URLs for the platform-specific downloader
    local temp_file=$(mktemp)
    printf '%s\n' "${urls[@]}" > "$temp_file"
    
    # Call the platform-specific downloader with the URLs
    if bash "$downloader_script" -u "$(IFS=','; echo "${urls[*]}")"; then
        log "Successfully downloaded $platform videos" "SUCCESS"
        rm "$temp_file"
        return 0
    else
        log "Failed to download some $platform videos" "ERROR"
        rm "$temp_file"
        return 1
    fi
}

# Track overall success
ALL_SUCCESS=true

# Process YouTube URLs
if [[ ${#YOUTUBE_URLS[@]} -gt 0 ]]; then
    if ! call_downloader "YouTube" "${YOUTUBE_URLS[@]}"; then
        ALL_SUCCESS=false
    fi
fi

# Process Facebook URLs
if [[ ${#FACEBOOK_URLS[@]} -gt 0 ]]; then
    if ! call_downloader "Facebook" "${FACEBOOK_URLS[@]}"; then
        ALL_SUCCESS=false
    fi
fi

# Process Gab URLs
if [[ ${#GAB_URLS[@]} -gt 0 ]]; then
    if ! call_downloader "Gab" "${GAB_URLS[@]}"; then
        ALL_SUCCESS=false
    fi
fi

# Handle unknown URLs
if [[ ${#UNKNOWN_URLS[@]} -gt 0 ]]; then
    log "Unsupported URLs detected:" "WARNING"
    for url in "${UNKNOWN_URLS[@]}"; do
        log "  - $url" "WARNING"
    done
    log "Please verify these URLs or add support for these platforms" "INFO"
    ALL_SUCCESS=false
fi

# Final summary
if [[ "$ALL_SUCCESS" == true ]]; then
    log "All downloads completed successfully!" "SUCCESS"
else
    log "Some downloads may have failed" "WARNING"
fi

