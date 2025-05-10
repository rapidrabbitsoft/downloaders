# GAB Video Downloader

This script takes GAB Video URLs and downloads the actual video.
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

* **Ubuntu/Debian**: `sudo apt install python3 python3-pip`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf python3 python3-pip && pip3 install -U`
* **macOS**: `brew install python3`
* **Windows**: Download binaries and add them to your `PATH`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu yt-dlp`

# Need python installed to process the HTML downloaded
~~~bash
pipenv shell
pipenv install
chmod +x extract.py downloads.sh
~~~