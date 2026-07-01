#!/usr/bin/env bash
set -Eeuo pipefail

ACTION="${1:-help}"

title() {
  printf '\n%s\n' "homelab-bootstrap azure-monitor"
  printf '%s\n\n' "==============================="
}

ok() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[ERROR] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ama_units() {
  systemctl list-units --all --type=service --no-legend 2>/dev/null \
    | awk '{print $1}' \
    | grep -Ei 'azure.*monitor|monitor.*agent|azuremonitor|mdsd|ama' || true
}

active_ama_unit() {
  for svc in $(ama_units); do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      echo "$svc"
      return 0
    fi
  done
  return 1
}

ama_presence_path() {
  find /opt/microsoft /var/lib/GuestConfig /var/lib/waagent \
    -maxdepth 6 \
    \( -iname '*azuremonitor*' -o -iname '*AzureMonitor*' -o -iname '*monitoragent*' \) \
    -print -quit 2>/dev/null || true
}

arc_connected() {
  if command -v azcmagent >/dev/null 2>&1; then
    azcmagent show 2>/dev/null | grep -Eiq 'Agent Status[[:space:]]*:[[:space:]]*Connected|Status[[:space:]]*:[[:space:]]*Connected'
  else
    return 1
  fi
}

show_help() {
  cat <<'HELP'
Usage:
  ./bootstrap.sh azure-monitor --dry-run
  ./bootstrap.sh azure-monitor --verify

Safety:
  This module verifies Azure Monitor Agent local presence only.
  It does not create data collection rules, workspaces, extensions, or secrets.
HELP
}

check_status() {
  title

  if arc_connected; then
    ok "Azure Arc connected"
  else
    warn "Azure Arc not connected or azcmagent missing"
  fi

  UNITS="$(ama_units)"
  if [ -n "$UNITS" ]; then
    ok "Azure Monitor related systemd units found"
    printf '%s\n' "$UNITS" | sed 's/^/[INFO] Unit: /'
  else
    warn "No Azure Monitor related systemd units found"
  fi

  ACTIVE_UNIT="$(active_ama_unit || true)"
  if [ -n "$ACTIVE_UNIT" ]; then
    ok "Azure Monitor related service active: $ACTIVE_UNIT"
  else
    warn "No Azure Monitor related service detected as active"
  fi

  PATH_FOUND="$(ama_presence_path)"
  if [ -n "$PATH_FOUND" ]; then
    ok "Azure Monitor local files found"
    info "$PATH_FOUND"
  else
    warn "Azure Monitor local files not found in common paths"
  fi
}

verify() {
  check_status

  echo

  if ! arc_connected; then
    fail "Azure Arc is not connected"
    exit 1
  fi

  if [ -z "$(active_ama_unit || true)" ] && [ -z "$(ama_presence_path)" ]; then
    fail "Azure Monitor Agent not detected locally"
    exit 1
  fi

  ok "Azure Monitor verification passed"
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
    fail "Unknown azure-monitor action: $ACTION"
    show_help
    exit 1
    ;;
esac
