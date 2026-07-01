#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/common.sh"

mode="${1:-guidance}"

show_guidance() {
  cat <<'TEXT'
Security Baseline

Recommended:
1. SSH keys
2. UFW enabled
3. Fail2Ban enabled
4. Tailscale for private remote access
5. No public Docker socket
6. No secrets in Git
7. Automatic security updates
8. Backups for configs and Docker volumes

Commands:
  ./bootstrap.sh security --dry-run
  ./bootstrap.sh security --apply

Safety:
- This module does NOT disable SSH password login.
- This module does NOT remove existing SSH firewall rules.
- This module does NOT force Tailscale-only SSH.
- Advanced SSH lock-down should be done only after key login is verified.
TEXT
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

write_file() {
  local path="$1"
  local content="$2"

  if [ "$DRY_RUN" = true ]; then
    echo "+ write file: $path"
    echo "$content"
  else
    echo "$content" | sudo tee "$path" >/dev/null
  fi
}

apply_security() {
  info "Applying safe security baseline"

  if [ "$DRY_RUN" = false ]; then
    sudo -v
  fi

  run_cmd "sudo apt update"
  run_cmd "sudo apt install -y openssh-server ufw fail2ban unattended-upgrades"

  run_cmd "sudo systemctl enable --now ssh"
  run_cmd "sudo systemctl enable --now fail2ban"

  run_cmd "sudo ufw default deny incoming"
  run_cmd "sudo ufw default allow outgoing"

  # Safe default: keep normal SSH allowed to avoid lockout.
  # Advanced Tailscale-only SSH can be added later.
  run_cmd "sudo ufw allow 22/tcp"

  if command_exists tailscale; then
    run_cmd "sudo ufw allow in on tailscale0 to any port 22 proto tcp || true"
  fi

  run_cmd "sudo ufw --force enable"

  write_file "/etc/ssh/sshd_config.d/99-homelab-baseline.conf" \
"PermitRootLogin no
PubkeyAuthentication yes"

  run_cmd "sudo /usr/sbin/sshd -t"
  run_cmd "sudo systemctl reload ssh"

  write_file "/etc/fail2ban/jail.d/sshd-homelab.local" \
"[sshd]
enabled = true
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h"

  run_cmd "sudo systemctl restart fail2ban"

  write_file "/etc/apt/apt.conf.d/20auto-upgrades" \
"APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";"

  info "Security baseline completed"
}

case "$mode" in
  --dry-run)
    DRY_RUN=true
    apply_security
    ;;
  --apply)
    DRY_RUN=false

    echo "This will apply safe baseline hardening."
    echo "It will NOT disable SSH password login."
    echo "It will NOT remove existing SSH access."
    echo
    read -r -p "Type APPLY to continue: " confirm

    if [ "$confirm" != "APPLY" ]; then
      echo "Cancelled."
      exit 0
    fi

    apply_security
    ;;
  guidance|"")
    show_guidance
    ;;
  *)
    error "Unknown security option: $mode"
    show_guidance
    exit 1
    ;;
esac
