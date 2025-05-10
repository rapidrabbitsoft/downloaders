# YouTube Video Downloader

This script takes YouTube Video URLs and downloads the actual video.
Alternatively you can add a list of urls in the downloads.txt file.

## Useage:

~~~bash
./download.sh --help
./download.sh -u url1
./download.sh -u url1,url2
# Define a downloads.txt file and download each url line by line
# NOTE: must have a blank space at the end the file
~~~

### Installation Requirements:

* **Ubuntu/Debian**: `sudo apt install python3 python3-pip ffmpeg`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf python3 python3-pip ffmpeg && pip3 install -U yt-dlp`
* **macOS**: `brew install ffmpeg yt-dlp`
* **Windows**: Download binaries and add them to your `PATH`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu yt-dlp`
