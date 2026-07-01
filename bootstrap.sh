#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/common.sh"

cmd="${1:-help}"
shift || true

show_help() {
  cat <<'HELP'
homelab-bootstrap

Usage:
  ./bootstrap.sh help
  ./bootstrap.sh doctor
  ./bootstrap.sh doctor --json
  ./bootstrap.sh doctor --sudo
  ./bootstrap.sh verify
  ./bootstrap.sh security
  ./bootstrap.sh security --dry-run
  ./bootstrap.sh security --apply
  ./bootstrap.sh security --tailscale-only-ssh-dry-run
  ./bootstrap.sh security --tailscale-only-ssh
  ./bootstrap.sh azure-arc
  ./bootstrap.sh azure-arc --dry-run
  ./bootstrap.sh azure-arc --verify
  ./bootstrap.sh azure-monitor
  ./bootstrap.sh azure-monitor --dry-run
  ./bootstrap.sh azure-monitor --verify
  ./bootstrap.sh update-manager
  ./bootstrap.sh update --dry-run
  ./bootstrap.sh update --apply
  ./bootstrap.sh docker --dry-run
  ./bootstrap.sh docker --apply
  ./bootstrap.sh docker --verify
  ./bootstrap.sh nvidia --dry-run
  ./bootstrap.sh nvidia --verify
  ./bootstrap.sh nvidia --container-test
  ./bootstrap.sh tailscale --dry-run
  ./bootstrap.sh tailscale --verify
  ./bootstrap.sh tailscale --netcheck

Commands:
  help                 Show help
  doctor               Run local health check
  doctor --json        Run local health check and output JSON
  doctor --sudo        Run health check with sudo-backed checks
  verify               Same as doctor
  security             Show security baseline guidance
  security --dry-run   Show security changes without applying
  security --apply     Apply safe baseline security hardening
  azure-arc            Verify Azure Arc connected machine status
  azure-monitor        Verify Azure Monitor Agent local readiness
  update-manager       Show Azure Update Manager guidance
  update               Safely check or apply Ubuntu package updates
  docker               Install or verify Docker Engine
  nvidia              Verify NVIDIA GPU and container readiness
  tailscale           Verify Tailscale remote access readiness
HELP
}

case "$cmd" in
  help|-h|--help)
    show_help
    ;;
  doctor|verify)
    bash "$ROOT_DIR/bootstrap/10-verify.sh" "$@"
    ;;
  security)
    bash "$ROOT_DIR/bootstrap/02-security.sh" "$@"
    ;;
  azure-arc)
    bash "$ROOT_DIR/bootstrap/07-azure-arc.sh" "$@"
    ;;
  azure-monitor)
    bash "$ROOT_DIR/bootstrap/08-azure-monitor.sh" "$@"
    ;;
  update-manager)
    bash "$ROOT_DIR/bootstrap/09-update-manager.sh" "$@"
    ;;
  update)
    bash "$ROOT_DIR/bootstrap/11-update.sh" "$@"
    ;;
  docker)
    bash "$ROOT_DIR/bootstrap/12-docker.sh" "$@"
    ;;
  nvidia)
    bash "$ROOT_DIR/bootstrap/13-nvidia.sh" "$@"
    ;;
  tailscale)
    bash "$ROOT_DIR/bootstrap/14-tailscale.sh" "$@"
    ;;
  *)
    error "Unknown command: $cmd"
    show_help
    exit 1
    ;;
esac
