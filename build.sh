#!/usr/bin/env bash
set -e

ZIP_DIR="docker-hosts"
ZIP_LINUX64="docker-hosts.linux64.zip"
ZIP_WIN64="docker-hosts.win64.zip"
ZIP_MACOS64="docker-hosts.macOS64.zip"

function cleanup() {
    if [ -f "docker-hosts.spec" ]; then rm "docker-hosts.spec"; fi
    if [ -d "./build" ]; then rm -Rf "./build"; fi
    if [ -d "./dist" ]; then rm -Rf "./dist"; fi
    if [ -d "./$ZIP_DIR" ]; then rm -Rf "./$ZIP_DIR"; fi
    if [ -d "./.pydeps" ]; then rm -Rf "./.pydeps"; fi
    mkdir "./.pydeps"
}

function build_linux() {
    cleanup
    pip3 install --target ".pydeps" --upgrade -r requirements_unix.txt
    pyinstaller -y --clean --noupx -F docker_hosts_unix.py

    mkdir "$ZIP_DIR"
    cp -R dist/docker_hosts_unix "$ZIP_DIR/docker-hosts"
    cp linux/setup.sh "$ZIP_DIR"
    zip -r "$ZIP_LINUX64" "$ZIP_DIR"
}

function build_macos() {
    cleanup
    pip3 install --target ".pydeps" --upgrade -r requirements_unix.txt
    pyinstaller -y --clean --noupx --onefile docker_hosts_unix.py
    mkdir "$ZIP_DIR"
    cp -R dist/docker_hosts_unix "$ZIP_DIR/docker-hosts"
    zip -r "$ZIP_MACOS64" "$ZIP_DIR"
}

function build_windows() {
    cleanup
    pyinstaller-windows -y --clean --hiddenimport win32timezone --runtime-tmpdir=. --onefile docker_hosts_windows.py
    mkdir "$ZIP_DIR"
    cp -R dist/docker_hosts_windows.exe "$ZIP_DIR/docker-hosts.exe"
    cp windows/setup.ps1 "$ZIP_DIR"
    zip -r "$ZIP_WIN64" "$ZIP_DIR"
}

if [ "$1" == "all" ]; then
    if [ -f "./$ZIP_LINUX64" ]; then rm "./$ZIP_LINUX64"; fi
    if [ -f "./$ZIP_WIN64" ]; then rm "./$ZIP_WIN64"; fi
    if [ -f "./$ZIP_MACOS64" ]; then rm "./$ZIP_MACOS64"; fi
    build_linux
    build_macos
    build_windows
fi

if [ "$1" == "linux" ]; then
    if [ -f "./$ZIP_LINUX64" ]; then rm "./$ZIP_LINUX64"; fi
    build_linux
fi

if [ "$1" == "macos" ]; then
    if [ -f "./$ZIP_MACOS64" ]; then rm "./$ZIP_MACOS64"; fi
    build_macos
fi

if [ "$1" == "windows" ]; then
    if [ -f "./$ZIP_WIN64" ]; then rm "./$ZIP_WIN64"; fi
    build_windows
fi
