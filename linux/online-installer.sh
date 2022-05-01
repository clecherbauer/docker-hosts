#!/usr/bin/env bash
set -e

VERSION="v1.2.0"

SOURCE_FILE="docker-hosts.linux64.zip"
SOURCE_DIR="docker-hosts"
RELEASE_URL="https://gitlab.com/api/v4/projects/35657590/releases/$VERSION/assets/links"

URL=$(wget -q -O - "$RELEASE_URL" | grep -Po '"direct_asset_url":*\K"[^"]*"' | grep "$SOURCE_FILE" | sed 's/"//g')
wget $URL

unzip -o "$SOURCE_FILE"
(
    cd "$SOURCE_DIR"
    ./setup.sh install
)

rm -Rf "$SOURCE_DIR"
