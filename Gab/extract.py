#!/usr/bin/env python3

"""
Video URL extractor for Gab platform.
This script extracts video URLs from Gab HTML content using BeautifulSoup.
"""

import argparse
import logging
import sys

from bs4 import BeautifulSoup


# Color codes for terminal output
class Colors:
    RED = "\033[1;31m"
    GREEN = "\033[1;32m"
    YELLOW = "\033[1;33m"
    CYAN = "\033[1;36m"
    RESET = "\033[0m"


# Custom formatter for colored output
class ColoredFormatter(logging.Formatter):
    """Custom formatter that adds colors to log levels"""

    COLORS = {
        "DEBUG": Colors.CYAN,
        "INFO": Colors.CYAN,
        "WARNING": Colors.YELLOW,
        "ERROR": Colors.RED,
        "CRITICAL": Colors.RED,
    }

    def format(self, record):
        # Get the color for this log level
        color = self.COLORS.get(record.levelname, Colors.RESET)

        # Format the record without color first
        formatted = super().format(record)

        # Add color to the entire line
        return f"{color}{formatted}{Colors.RESET}"


# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Create console handler with colored output
console_handler = logging.StreamHandler()
console_handler.setFormatter(
    ColoredFormatter(
        "[%(asctime)s] [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )
)

# Create file handler for plain text logging
file_handler = logging.FileHandler("extract.log")
file_handler.setFormatter(
    logging.Formatter(
        "[%(asctime)s] [%(levelname)s] [%(message)s]", datefmt="%Y-%m-%d %H:%M:%S"
    )
)

# Add handlers to logger
logger.addHandler(console_handler)
logger.addHandler(file_handler)


def extract_video_url_from_file(filename):
    """
    Extract video URL from an HTML file.

    Args:
        filename (str): Path to the HTML file

    Returns:
        str: Video URL if found, empty string otherwise
    """
    try:
        with open(filename, "r", encoding="utf-8") as file:
            html_content = file.read()

        soup = BeautifulSoup(html_content, "html.parser")

        # Try to find video URL in meta tags
        og_video_tag = soup.find("meta", property="og:video")
        if og_video_tag:
            video_url = og_video_tag.get("content")
            logger.debug("Found video URL in og:video meta tag")
            return video_url

        # Try alternative meta tag
        video_tag = soup.find("meta", property="video")
        if video_tag:
            video_url = video_tag.get("content")
            logger.debug("Found video URL in video meta tag")
            return video_url

        logger.warning("No video URL found in HTML content")
        return ""

    except FileNotFoundError:
        logger.error(f"File not found: {filename}")
        return ""
    except Exception as e:
        logger.error(f"Error processing file: {str(e)}")
        return ""


def main():
    """Main function to handle command line arguments and execute the extraction."""
    parser = argparse.ArgumentParser(
        description="Extract video URL from Gab HTML content.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--file", type=str, required=True, help="HTML file to parse")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")

    args = parser.parse_args()

    if args.debug:
        logger.setLevel(logging.DEBUG)

    video_url = extract_video_url_from_file(args.file)
    if video_url:
        print(video_url)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
