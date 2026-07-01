#!/usr/bin/env bash
set -Eeuo pipefail

ACTION="${1:-help}"

title() {
  printf '\n%s\n' "homelab-bootstrap azure-arc"
  printf '%s\n\n' "==========================="
}

ok() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[ERROR] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

agent_show() {
  azcmagent show 2>/dev/null || true
}

agent_connected() {
  agent_show | grep -Eiq 'Agent Status[[:space:]]*:[[:space:]]*Connected|Status[[:space:]]*:[[:space:]]*Connected'
}

show_help() {
  cat <<'HELP'
Usage:
  ./bootstrap.sh azure-arc --dry-run
  ./bootstrap.sh azure-arc --verify

Safety:
  This module verifies Azure Arc only.
  It does not onboard, disconnect, create service principals, or store secrets.
HELP
}

check_status() {
  title

  if has_cmd azcmagent; then
    ok "Azure Connected Machine Agent installed: $(azcmagent version 2>/dev/null | head -1 || true)"
  else
    warn "azcmagent missing"
  fi

  if has_cmd azcmagent && [ -n "$(agent_show)" ]; then
    ok "azcmagent show readable"
    agent_show | grep -E 'Resource Name|Resource Group|Subscription ID|Tenant ID|Location|Agent Version|Agent Status' || true
  else
    warn "azcmagent show not readable"
  fi

  if has_cmd azcmagent && agent_connected; then
    ok "Azure Arc agent status connected"
  else
    warn "Azure Arc agent status not connected"
  fi

  for svc in himdsd arcproxyd extd gcad; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      ok "Arc service active: $svc"
    else
      warn "Arc service not active or not found: $svc"
    fi
  done
}

verify() {
  check_status

  echo

  if ! has_cmd azcmagent; then
    fail "azcmagent missing"
    exit 1
  fi

  if [ -z "$(agent_show)" ]; then
    fail "azcmagent show not readable"
    exit 1
  fi

  if ! agent_connected; then
    fail "Azure Arc agent is not connected"
    exit 1
  fi

  ok "Azure Arc verification passed"
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
  *)
    fail "Unknown azure-arc action: $ACTION"
    show_help
    exit 1
    ;;
esac
