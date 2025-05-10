#!/bin/bash

# Color codes
BOLD='\033[1m'
GREEN='\033[1m;32m'
RED='\033[1m;31m'
YELLOW='\033[1m;33m'
CYAN='\033[1m;36m'
MAGENTA='\033[1m;35m'
NC='\033[0m'

# Default values
URLS=()

# failed URLs
FAILED_URLS=()


# Display usage
usage() {
    echo -e "${CYAN}Usage:${NC} $0 [-u url1,url2,...]"
    echo -e "       -h, --help  Display this help message"
    exit 1
}

# Parse flags
while [[ "$1" == -* ]]; do
    case "$1" in
        -u)
            IFS=',' read -ra URLS <<< "$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *) usage ;;
    esac
done

# If no URLs are provided via flags, check for downloads.txt file in the current directory
if [[ ${#URLS[@]} -eq 0 ]]; then
    if [[ -f "downloads.txt" ]]; then
        # Read each line from the file into the URLS array
        while IFS= read -r line; do
            echo "$line"
            URLS+=("$line")
        done < "downloads.txt"
    else
        echo -e "${RED}Error:${NC} No valid URLs supplied for downloading1"
        exit 1
    fi
fi

# Ensure that we have a valid list of URLs
if [[ ${#URLS[@]} -eq 0 ]]; then
    echo -e "${RED}Error:${NC} No valid URLs supplied for downloading2"
    exit 1
fi

# Ensure downloads folder exists
mkdir -p Downloads

# Start downloading
echo -e "${CYAN}🔄 Starting to download videos${NC}"

# Loop through each URL
for url in "${URLS[@]}"; do
    echo -e "${CYAN}🔄 Processing URL:${NC} $url"

    # Fetch the HTML content of the page
    html_content=$(curl -s "$url")

    # Store the HTML content in a temp file
    temp_file=$(mktemp)
    echo "$html_content" > "$temp_file"

    # Using a Python script to extract the video URL for downloading
    video_url=$(python3 extract.py --file "$temp_file")

    if [ -n "$video_url" ]; then
        echo -e "${GREEN}✅ Found video URL:${NC} $video_url"

        # Extract the filename from the video URL (basename)
        video_filename=$(basename "$video_url")
        target_path="Downloads/$video_filename"

        # Check if file already exists
        if [ -f "$target_path" ]; then
            echo -e "${YELLOW}⚠️  File already exists, Skipping: ${NC}$target_path"
            continue
        fi

        # Download the video using wget
        echo -e "${YELLOW}⚠️  Downloading video:${NC} $video_filename"
        wget -q "$video_url" -O "$target_path"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Video Downloaded: $video_filename${NC}"
        else
            echo -e "${RED}❌ Video Download Failed: $video_filename${NC}"
            FAILED_URLS+=("$url")
        fi
    else
        echo -e "${RED}❌ Video Not Found: $url${NC}"
        FAILED_URLS+=("$url")
    fi
done

# Print failed URLs at the end
if [ ${#FAILED_URLS[@]} -ne 0 ]; then
    echo -e "\n${RED}Some downloads failed (downloads.txt updated):${NC}"
    rm downloads.txt
    for failed_url in "${FAILED_URLS[@]}"; do
        echo "$failed_url"
    done > downloads.txt
else
    rm downloads.txt
    touch downloads.txt
    echo -e "\n${GREEN}🎉 All videos downloaded successfully!${NC}"
fi
