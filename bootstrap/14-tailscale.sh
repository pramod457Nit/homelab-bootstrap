#!/usr/bin/env bash
set -Eeuo pipefail

ACTION="${1:-help}"

title() {
  printf '\n%s\n' "homelab-bootstrap tailscale"
  printf '%s\n\n' "==========================="
}

ok() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[ERROR] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

tailscale_ip4() {
  tailscale ip -4 2>/dev/null | head -1 || true
}

show_help() {
  cat <<'HELP'
Usage:
  ./bootstrap.sh tailscale --dry-run
  ./bootstrap.sh tailscale --verify
  ./bootstrap.sh tailscale --netcheck

What it does:
  --dry-run    Show Tailscale readiness status
  --verify     Verify tailscaled, tailscale0, Tailscale IP, and SSH firewall posture
  --netcheck   Run tailscale netcheck

Safety:
  This module does not run tailscale up.
  Do not put auth keys or secrets in this repo.
HELP
}

check_ufw_ssh() {
  if ! has_cmd ufw; then
    warn "UFW missing"
    return 0
  fi

  if ! sudo -n true 2>/dev/null; then
    warn "Skipping UFW SSH posture check because sudo is not cached"
    info "Run: sudo -v && ./bootstrap.sh tailscale --verify"
    return 0
  fi

  UFW_STATUS="$(sudo ufw status 2>/dev/null || true)"
  SSH_ALLOW_LINES="$(printf '%s\n' "$UFW_STATUS" | awk '/22\/tcp/ && /ALLOW/ {print}')"

  if [ -z "$SSH_ALLOW_LINES" ]; then
    warn "No SSH allow rule found in UFW"
    return 0
  fi

  if printf '%s\n' "$SSH_ALLOW_LINES" | grep -v 'tailscale0' | grep -q .; then
    fail "Broad SSH allow rule found outside tailscale0"
    printf '%s\n' "$SSH_ALLOW_LINES" | sed 's/^/[INFO] SSH rule: /'
    return 1
  fi

  ok "SSH is restricted to tailscale0"
  ok "No broad public SSH allow rule found"
}

check_status() {
  title

  if has_cmd tailscale; then
    ok "Tailscale CLI installed: $(tailscale version 2>/dev/null | head -1)"
  else
    warn "Tailscale CLI missing"
  fi

  if systemctl is-active --quiet tailscaled 2>/dev/null; then
    ok "tailscaled service active"
  else
    warn "tailscaled service not active"
  fi

  if ip link show tailscale0 >/dev/null 2>&1; then
    ok "tailscale0 interface exists"
  else
    warn "tailscale0 interface missing"
  fi

  if has_cmd tailscale; then
    IP4="$(tailscale_ip4)"
    if [ -n "$IP4" ]; then
      ok "Tailscale IPv4: $IP4"
    else
      warn "No Tailscale IPv4 found"
    fi

    if tailscale status >/dev/null 2>&1; then
      ok "tailscale status readable"
    else
      warn "tailscale status not readable"
    fi
  fi

  check_ufw_ssh
}

verify() {
  check_status

  echo

  if ! has_cmd tailscale; then
    fail "Tailscale CLI missing"
    exit 1
  fi

  if ! systemctl is-active --quiet tailscaled 2>/dev/null; then
    fail "tailscaled service not active"
    exit 1
  fi

  if ! ip link show tailscale0 >/dev/null 2>&1; then
    fail "tailscale0 interface missing"
    exit 1
  fi

  if [ -z "$(tailscale_ip4)" ]; then
    fail "Tailscale IPv4 missing"
    exit 1
  fi

  if ! tailscale status >/dev/null 2>&1; then
    fail "tailscale status failed"
    exit 1
  fi

  ok "Tailscale verification passed"
}

netcheck() {
  title

  if ! has_cmd tailscale; then
    fail "Tailscale CLI missing"
    exit 1
  fi

  tailscale netcheck 2>/dev/null
}

case "$ACTION" in
  help|-h|--help)
    show_help
    ;;
  --dry-run)
    check_status
    info "Dry run only. No changes applied."
    ;;
  --verify)
    verify
    ;;
  --netcheck)
    netcheck
    ;;
  *)
    fail "Unknown tailscale action: $ACTION"
    show_help
    exit 1
    ;;
esac
