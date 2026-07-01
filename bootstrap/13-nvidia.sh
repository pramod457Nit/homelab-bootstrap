#!/usr/bin/env bash
set -Eeuo pipefail

ACTION="${1:-help}"

title() {
  printf '\n%s\n' "homelab-bootstrap nvidia"
  printf '%s\n\n' "========================"
}

ok() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[ERROR] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

show_help() {
  cat <<'HELP'
Usage:
  ./bootstrap.sh nvidia --dry-run
  ./bootstrap.sh nvidia --verify
  ./bootstrap.sh nvidia --container-test

What it does:
  --dry-run          Show NVIDIA/GPU readiness status
  --verify           Verify NVIDIA driver, nvidia-smi, Docker, and NVIDIA container tooling
  --container-test   Run Docker GPU test using NVIDIA CUDA image

Safety:
  This module does not install or change NVIDIA drivers.
HELP
}

check_status() {
  title

  if has_cmd lspci && lspci | grep -qi nvidia; then
    ok "NVIDIA GPU detected by lspci"
  else
    warn "NVIDIA GPU not detected by lspci, or lspci missing"
  fi

  if has_cmd nvidia-smi; then
    ok "nvidia-smi installed"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || true
  else
    warn "nvidia-smi missing"
  fi

  if has_cmd docker; then
    ok "Docker CLI installed: $(docker --version)"
  else
    warn "Docker CLI missing"
  fi

  if systemctl is-active --quiet docker 2>/dev/null; then
    ok "Docker service active"
  else
    warn "Docker service not active"
  fi

  if has_cmd nvidia-ctk; then
    ok "nvidia-ctk installed: $(nvidia-ctk --version 2>/dev/null | head -1)"
  else
    warn "nvidia-ctk missing"
  fi

  if has_cmd nvidia-container-cli; then
    ok "nvidia-container-cli installed: $(nvidia-container-cli --version 2>/dev/null | head -1)"
  else
    warn "nvidia-container-cli missing"
  fi

  if dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
    ok "nvidia-container-toolkit package installed"
  else
    warn "nvidia-container-toolkit package missing"
  fi

  if [ -f /etc/docker/daemon.json ] && grep -qi nvidia /etc/docker/daemon.json; then
    ok "Docker daemon.json references NVIDIA runtime"
  else
    warn "Docker daemon.json does not reference NVIDIA runtime"
    info "This may still be okay if Docker GPU test passes."
  fi
}

verify() {
  check_status

  echo

  if ! has_cmd nvidia-smi; then
    fail "nvidia-smi missing"
    exit 1
  fi

  if ! nvidia-smi >/dev/null 2>&1; then
    fail "nvidia-smi failed"
    exit 1
  fi

  if ! has_cmd docker; then
    fail "Docker missing"
    exit 1
  fi

  if ! systemctl is-active --quiet docker 2>/dev/null; then
    fail "Docker service not active"
    exit 1
  fi

  if ! has_cmd nvidia-container-cli && ! has_cmd nvidia-ctk; then
    fail "NVIDIA container tooling missing"
    exit 1
  fi

  ok "NVIDIA local verification passed"
  info "Container GPU test is separate because it may pull a large CUDA image."
  info "Run:"
  info "  ./bootstrap.sh nvidia --container-test"
}

container_test() {
  title

  if ! has_cmd docker; then
    fail "Docker missing"
    exit 1
  fi

  if ! has_cmd nvidia-smi; then
    fail "nvidia-smi missing"
    exit 1
  fi

  warn "This may pull a large NVIDIA CUDA image."
  read -r -p "Type NVIDIA to continue: " confirm

  if [ "$confirm" != "NVIDIA" ]; then
    fail "Aborted"
    exit 1
  fi

  docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu24.04 nvidia-smi
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
  --container-test)
    container_test
    ;;
  *)
    fail "Unknown nvidia action: $ACTION"
    show_help
    exit 1
    ;;
esac
