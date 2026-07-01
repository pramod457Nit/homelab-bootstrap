#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_ubuntu() {
  [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release
}

ubuntu_version() {
  . /etc/os-release
  echo "${VERSION_ID:-unknown}"
}

service_active() {
  systemctl is-active --quiet "$1"
}

has_nvidia_gpu() {
  lspci 2>/dev/null | grep -qi nvidia
}
