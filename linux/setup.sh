#!/usr/bin/env bash
set -e

DOCKER_HOSTS_BINARY_ROOT="/usr/local/bin"
DOCKER_HOSTS_BINARY="docker-hosts"

SYSTEMD_ROOT_DIR="/etc/systemd/system"
SYSTEMD_SERVICE_FILE="docker-hosts.service"
SYSTEMD_SYMLINK="$SYSTEMD_ROOT_DIR/$SYSTEMD_SERVICE_FILE"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

function install() {
  systemctl stop "$SYSTEMD_SERVICE_FILE" || true
  chmod +x "$DOCKER_HOSTS_BINARY"
  cp -r "$DOCKER_HOSTS_BINARY" "$DOCKER_HOSTS_BINARY_ROOT"
  ln -s "$DOCKER_HOSTS_BINARY_ROOT/$DOCKER_HOSTS_BINARY" "$SYSTEMD_SYMLINK"

  systemctl daemon-reload
  systemctl enable "$SYSTEMD_SERVICE_FILE"
  systemctl start "$SYSTEMD_SERVICE_FILE"
}

function uninstall() {
  systemctl stop "$SYSTEMD_SERVICE_FILE" || true
  systemctl disable "$SYSTEMD_SERVICE_FILE" || true

  rm "$DOCKER_HOSTS_BINARY" "$DOCKER_HOSTS_BINARY_ROOT/$DOCKER_HOSTS_BINARY"
  rm "$SYSTEMD_SYMLINK"
}

if [ "$1" == "install" ]; then
  install
fi

if [ "$1" == "uninstall" ]; then
  uninstall
fi