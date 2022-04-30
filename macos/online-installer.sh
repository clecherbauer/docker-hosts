#!/usr/bin/env bash
set -e

VERSION="v1.0.0-beta"
SOURCE_FILE="docker-hosts.macOS64.zip"
SOURCE_DIR="docker-hosts"


URL=$(wget -q -O - "https://gitlab.com/api/v4/projects/35657590/releases/"$VERSION"/assets/links" | grep -Po '"direct_asset_url":*\K"[^"]*"' | grep "$SOURCE_FILE" | sed 's/"//g')
wget $URL

unzip -o "$SOURCE_FILE"
(
  cd "$SOURCE_DIR"
  #./setup.sh
)

rm -Rf "$SOURCE_DIR"
