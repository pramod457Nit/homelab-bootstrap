#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/common.sh"

cmd="${1:-help}"

show_help() {
  cat <<'HELP'
homelab-bootstrap

Usage:
  ./bootstrap.sh help
  ./bootstrap.sh doctor
  ./bootstrap.sh verify
  ./bootstrap.sh security
  ./bootstrap.sh azure-arc
  ./bootstrap.sh azure-monitor
  ./bootstrap.sh update-manager

Commands:
  help             Show help
  doctor           Run local health check
  verify           Same as doctor for now
  security         Show security baseline guidance
  azure-arc        Show Azure Arc onboarding guidance
  azure-monitor    Show Azure Monitor guidance
  update-manager   Show Azure Update Manager guidance
HELP
}

case "$cmd" in
  help|-h|--help)
    show_help
    ;;
  doctor|verify)
    bash "$ROOT_DIR/bootstrap/10-verify.sh"
    ;;
  security)
    bash "$ROOT_DIR/bootstrap/02-security.sh"
    ;;
  azure-arc)
    bash "$ROOT_DIR/bootstrap/07-azure-arc.sh"
    ;;
  azure-monitor)
    bash "$ROOT_DIR/bootstrap/08-azure-monitor.sh"
    ;;
  update-manager)
    bash "$ROOT_DIR/bootstrap/09-update-manager.sh"
    ;;
  *)
    error "Unknown command: $cmd"
    show_help
    exit 1
    ;;
esac
