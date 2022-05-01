#!/usr/bin/env bash
set -e

DOCKER_HOSTS_BINARY_ROOT="/usr/local/bin"
DOCKER_HOSTS_BINARY="docker-hosts"

if [ "$EUID" -ne 0 ]
    then echo "Please run this as root"
    exit
fi

function install() {
    if [ -x "$(command -v docker-hosts)" ]; then
        docker-hosts stop
    fi
    chmod +x "$DOCKER_HOSTS_BINARY"
    cp ./bu"$DOCKER_HOSTS_BINARY" "$DOCKER_HOSTS_BINARY_ROOT"
}

function uninstall() {
    if [ -x "$(command -v docker-hosts)" ]; then
        docker-hosts stop
    fi
    rm "$DOCKER_HOSTS_BINARY"
}

if [ "$1" == "install" ]; then
    install
fi

if [ "$1" == "uninstall" ]; then
    uninstall
fi