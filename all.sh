#!/bin/bash

# All Downloaders Script
# Runs all download scripts in subdirectories with prefixed flags
# Supports: YouTube, Gab, Facebook

# Color codes for prettifying the output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
NC='\033[0m'  # No Color

# Script paths
YOUTUBE_SCRIPT="YouTube/download.sh"
GAB_SCRIPT="Gab/download.sh"
FACEBOOK_SCRIPT="Facebook/download.sh"

# Default values for each service
YOUTUBE_URLS=""
YOUTUBE_DIR=""
YOUTUBE_RETRIES=""
YOUTUBE_LIST_FORMATS=""

GAB_URLS=""
GAB_DIR=""
GAB_RETRIES=""

FACEBOOK_URLS=""
FACEBOOK_DIR=""
FACEBOOK_RETRIES=""
FACEBOOK_LIST_FORMATS=""

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
    log "Usage: $0 [OPTIONS]" "INFO"
    log "" "INFO"
    log "Global Options:" "INFO"
    log "  --youtube-only     Run only YouTube downloads" "INFO"
    log "  --gab-only         Run only Gab downloads" "INFO"
    log "  --facebook-only    Run only Facebook downloads" "INFO"
    log "  --skip-youtube     Skip YouTube downloads" "INFO"
    log "  --skip-gab         Skip Gab downloads" "INFO"
    log "  --skip-facebook    Skip Facebook downloads" "INFO"
    log "  -h, --help         Display this help message" "INFO"
    log "" "INFO"
    log "YouTube Options (--youtube-*):" "INFO"
    log "  --youtube-urls     Comma-separated list of YouTube URLs" "INFO"
    log "  --youtube-dir      Download directory (default: YouTube/Downloads)" "INFO"
    log "  --youtube-retries  Number of retry attempts (default: 3)" "INFO"
    log "  --youtube-list-formats  List available formats without downloading" "INFO"
    log "" "INFO"
    log "Gab Options (--gab-*):" "INFO"
    log "  --gab-urls         Comma-separated list of Gab URLs" "INFO"
    log "  --gab-dir          Download directory (default: Gab/Downloads)" "INFO"
    log "  --gab-retries      Number of retry attempts (default: 3)" "INFO"
    log "" "INFO"
    log "Facebook Options (--facebook-*):" "INFO"
    log "  --facebook-urls    Comma-separated list of Facebook URLs" "INFO"
    log "  --facebook-dir     Download directory (default: Facebook/Downloads)" "INFO"
    log "  --facebook-retries Number of retry attempts (default: 3)" "INFO"
    log "  --facebook-list-formats List available formats without downloading" "INFO"
    log "" "INFO"
    log "Examples:" "INFO"
    log "  $0 --youtube-retries 5 --gab-dir /custom/path" "INFO"
    log "  $0 --youtube-only --youtube-urls 'url1,url2'" "INFO"
    log "  $0 --skip-facebook --youtube-list-formats" "INFO"
    exit 1
}

# Function to build command line arguments for a service
build_service_args() {
    local service="$1"
    local args=""
    
    case "$service" in
        "YouTube")
            if [[ -n "$YOUTUBE_URLS" ]]; then
                args="$args -u '$YOUTUBE_URLS'"
            fi
            if [[ -n "$YOUTUBE_DIR" ]]; then
                args="$args -d '$YOUTUBE_DIR'"
            fi
            if [[ -n "$YOUTUBE_RETRIES" ]]; then
                args="$args -r '$YOUTUBE_RETRIES'"
            fi
            if [[ "$YOUTUBE_LIST_FORMATS" == "true" ]]; then
                args="$args -f"
            fi
            ;;
        "Gab")
            if [[ -n "$GAB_URLS" ]]; then
                args="$args -u '$GAB_URLS'"
            fi
            if [[ -n "$GAB_DIR" ]]; then
                args="$args -d '$GAB_DIR'"
            fi
            if [[ -n "$GAB_RETRIES" ]]; then
                args="$args -r '$GAB_RETRIES'"
            fi
            ;;
        "Facebook")
            if [[ -n "$FACEBOOK_URLS" ]]; then
                args="$args -u '$FACEBOOK_URLS'"
            fi
            if [[ -n "$FACEBOOK_DIR" ]]; then
                args="$args -d '$FACEBOOK_DIR'"
            fi
            if [[ -n "$FACEBOOK_RETRIES" ]]; then
                args="$args -r '$FACEBOOK_RETRIES'"
            fi
            if [[ "$FACEBOOK_LIST_FORMATS" == "true" ]]; then
                args="$args -f"
            fi
            ;;
    esac
    
    echo "$args"
}

# Function to run a service downloader
run_service() {
    local service="$1"
    local script_path="$2"
    
    if [[ ! -f "$script_path" ]]; then
        log "Script not found: $script_path" "WARNING"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log "Making script executable: $script_path" "INFO"
        chmod +x "$script_path"
    fi
    
    log "Running $service downloads..." "INFO"
    
    # Build arguments
    local args
    args=$(build_service_args "$service")
    
    # Change to the service directory
    local service_dir=$(dirname "$script_path")
    cd "$service_dir" || {
        log "Failed to change to directory: $service_dir" "ERROR"
        return 1
    }
    
    # Run the script
    log "Executing: ./$(basename "$script_path")$args" "INFO"
    local result=0
    if eval "./$(basename "$script_path")$args"; then
        log "$service downloads completed successfully" "SUCCESS"
    else
        log "$service downloads failed" "ERROR"
        result=1
    fi
    
    # Return to original directory
    cd - > /dev/null
    
    return $result
}

# Parse command line arguments
YOUTUBE_ONLY=false
GAB_ONLY=false
FACEBOOK_ONLY=false
SKIP_YOUTUBE=false
SKIP_GAB=false
SKIP_FACEBOOK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        # Global options
        --youtube-only)
            YOUTUBE_ONLY=true
            shift
            ;;
        --gab-only)
            GAB_ONLY=true
            shift
            ;;
        --facebook-only)
            FACEBOOK_ONLY=true
            shift
            ;;
        --skip-youtube)
            SKIP_YOUTUBE=true
            shift
            ;;
        --skip-gab)
            SKIP_GAB=true
            shift
            ;;
        --skip-facebook)
            SKIP_FACEBOOK=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        
        # YouTube options
        --youtube-urls)
            YOUTUBE_URLS="$2"
            shift 2
            ;;
        --youtube-dir)
            YOUTUBE_DIR="$2"
            shift 2
            ;;
        --youtube-retries)
            YOUTUBE_RETRIES="$2"
            shift 2
            ;;
        --youtube-list-formats)
            YOUTUBE_LIST_FORMATS="true"
            shift
            ;;
        
        # Gab options
        --gab-urls)
            GAB_URLS="$2"
            shift 2
            ;;
        --gab-dir)
            GAB_DIR="$2"
            shift 2
            ;;
        --gab-retries)
            GAB_RETRIES="$2"
            shift 2
            ;;
        
        # Facebook options
        --facebook-urls)
            FACEBOOK_URLS="$2"
            shift 2
            ;;
        --facebook-dir)
            FACEBOOK_DIR="$2"
            shift 2
            ;;
        --facebook-retries)
            FACEBOOK_RETRIES="$2"
            shift 2
            ;;
        --facebook-list-formats)
            FACEBOOK_LIST_FORMATS="true"
            shift
            ;;
        
        *)
            log "Unknown option: $1" "ERROR"
            usage
            ;;
    esac
done

# Determine which services to run
RUN_YOUTUBE=false
RUN_GAB=false
RUN_FACEBOOK=false

if [[ "$YOUTUBE_ONLY" == true ]]; then
    RUN_YOUTUBE=true
elif [[ "$GAB_ONLY" == true ]]; then
    RUN_GAB=true
elif [[ "$FACEBOOK_ONLY" == true ]]; then
    RUN_FACEBOOK=true
else
    # Run all services unless explicitly skipped
    if [[ "$SKIP_YOUTUBE" != true ]]; then
        RUN_YOUTUBE=true
    fi
    if [[ "$SKIP_GAB" != true ]]; then
        RUN_GAB=true
    fi
    if [[ "$SKIP_FACEBOOK" != true ]]; then
        RUN_FACEBOOK=true
    fi
fi

# Main execution
log "Starting all downloaders..." "INFO"

# Run YouTube downloads
if [[ "$RUN_YOUTUBE" == true ]]; then
    run_service "YouTube" "$YOUTUBE_SCRIPT"
fi

# Run Gab downloads
if [[ "$RUN_GAB" == true ]]; then
    run_service "Gab" "$GAB_SCRIPT"
fi

# Run Facebook downloads
if [[ "$RUN_FACEBOOK" == true ]]; then
    run_service "Facebook" "$FACEBOOK_SCRIPT"
fi

log "All downloaders completed!" "SUCCESS" 