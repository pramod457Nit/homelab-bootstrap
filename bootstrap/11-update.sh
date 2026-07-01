#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/logger.sh"

mode="${1:-guidance}"
REPORT_DIR="$HOME/.local/share/homelab-bootstrap/reports"
REPORT_FILE="$REPORT_DIR/update-$(date +%Y%m%d-%H%M%S).log"

show_guidance() {
  cat <<'TEXT'
Update Module

Commands:
  ./bootstrap.sh update --dry-run
  ./bootstrap.sh update --apply

Behavior:
- Dry-run updates package metadata and shows pending upgrades.
- Apply runs normal Ubuntu package upgrades.
- It does not run dist-upgrade/full-upgrade.
- It does not autoremove packages automatically.
- It reports if reboot is required.

Recommended:
- Run dry-run first.
- Run apply only when you have time to reboot if needed.
TEXT
}

dry_run_update() {
  mkdir -p "$REPORT_DIR"

  {
    echo "Update dry-run report"
    echo "Date: $(date)"
    echo

    info "Updating package metadata"
    sudo apt update

    echo
    echo "Upgradeable packages:"
    apt list --upgradable 2>/dev/null || true

    echo
    echo "Simulated upgrade:"
    sudo apt -s upgrade || true

    echo
    echo "Reboot status:"
    if [ -f /var/run/reboot-required ]; then
      echo "Reboot required"
      cat /var/run/reboot-required.pkgs 2>/dev/null || true
    else
      echo "No reboot required currently"
    fi
  } | tee "$REPORT_FILE"

  info "Dry-run report saved to $REPORT_FILE"
}

apply_update() {
  mkdir -p "$REPORT_DIR"

  echo "This will apply Ubuntu package updates."
  echo "It will NOT run dist-upgrade/full-upgrade."
  echo "It will NOT autoremove packages."
  echo
  read -r -p "Type UPDATE to continue: " confirm

  if [ "$confirm" != "UPDATE" ]; then
    echo "Cancelled."
    exit 0
  fi

  {
    echo "Update apply report"
    echo "Date: $(date)"
    echo

    info "Updating package metadata"
    sudo apt update

    info "Applying normal package upgrades"
    sudo apt upgrade -y

    echo
    echo "Reboot status:"
    if [ -f /var/run/reboot-required ]; then
      echo "Reboot required"
      cat /var/run/reboot-required.pkgs 2>/dev/null || true
    else
      echo "No reboot required"
    fi
  } | tee "$REPORT_FILE"

  info "Update report saved to $REPORT_FILE"
}

case "$mode" in
  --dry-run)
    dry_run_update
    ;;
  --apply)
    apply_update
    ;;
  guidance|"")
    show_guidance
    ;;
  *)
    error "Unknown update option: $mode"
    show_guidance
    exit 1
    ;;
esac
