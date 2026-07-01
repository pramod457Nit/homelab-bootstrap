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

ufw_ssh_restricted_to_tailscale() {
  local status

  if [ "$EUID" -eq 0 ]; then
    status="$(ufw status verbose 2>/dev/null)" || return 1
  elif sudo -n true 2>/dev/null; then
    status="$(sudo -n ufw status verbose 2>/dev/null)" || return 1
  else
    return 1
  fi

  echo "$status" | grep -Eq '^22/tcp[[:space:]]+on tailscale0[[:space:]]+ALLOW IN' || return 1

  if echo "$status" | grep -Eq '^22/tcp[[:space:]]+ALLOW IN[[:space:]]+Anywhere'; then
    return 1
  fi

  if echo "$status" | grep -Eq '^22/tcp \(v6\)[[:space:]]+ALLOW IN[[:space:]]+Anywhere'; then
    return 1
  fi

  return 0
}
