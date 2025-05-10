#!/usr/bin/env python3

import argparse
from bs4 import BeautifulSoup

def extract_video_url_from_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as file:
            html_content = file.read()
        soup = BeautifulSoup(html_content, 'html.parser')
        og_video_tag = soup.find('meta', property='og:video')
        if og_video_tag:
            return og_video_tag.get('content')
        else:
            return ""
    except FileNotFoundError:
        return ""
    except Exception as e:
        return ""

def main():
    parser = argparse.ArgumentParser(description='Extract og:video content from an HTML file.')
    parser.add_argument('--file', type=str, required=True, help='HTML file to parse')
    args = parser.parse_args()
    print(extract_video_url_from_file(args.file))

if __name__ == '__main__':
    main()
