# Gab Video Downloader

A script for downloading videos from the Gab platform. Supports both single video downloads and bulk downloads from a list.

## Features

- Downloads videos from Gab platform
- Supports both single URLs and bulk downloads
- Automatic video URL extraction from HTML
- Error handling and failed download tracking
- Progress indicators and colored output

## Usage

### Single Video Download
```bash
./download.sh -u "https://gab.com/video/VIDEO_ID"
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
sudo apt install python3 python3-pip
pip3 install beautifulsoup4 requests
```

### CentOS/RHEL/Fedora
```bash
sudo yum/dnf install python3 python3-pip
pip3 install beautifulsoup4 requests
```

### macOS
```bash
brew install python3
pip3 install beautifulsoup4 requests
```

### Windows
1. Download and install Python from [python.org](https://python.org)
2. Install required packages:
```bash
pip install beautifulsoup4 requests
```

### Arch Linux/Manjaro
```bash
sudo pacman -Syu python-beautifulsoup4 python-requests
```

## Setup

1. Install Python dependencies:
```bash
pipenv shell
pipenv install
```

2. Make scripts executable:
```bash
chmod +x extract.py download.sh
```

## Notes

- Downloaded videos are saved in the `Downloads` directory
- Failed downloads are automatically tracked and saved to `downloads.txt`
- The script requires an empty line at the end of `downloads.txt`
- The script uses BeautifulSoup for HTML parsing and video URL extraction