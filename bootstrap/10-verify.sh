#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/common.sh"

score=0
total=0

check() {
  local name="$1"
  shift
  total=$((total + 1))

  if "$@" >/dev/null 2>&1; then
    pass "$name"
    score=$((score + 1))
  else
    fail "$name"
  fi
}

optional_skip() {
  local name="$1"
  skip "$name"
}

echo
echo "homelab-bootstrap doctor"
echo "========================"
echo

check "Ubuntu" is_ubuntu

if is_ubuntu; then
  version="$(ubuntu_version)"
  echo "INFO  Ubuntu version: $version"
fi

check "Git installed" command_exists git
check "Curl installed" command_exists curl
check "SSH service active" service_active ssh
check "UFW installed" command_exists ufw
check "Fail2Ban installed" command_exists fail2ban-client
check "Docker installed" command_exists docker
check "Docker service active" service_active docker
check "Docker Compose installed" docker compose version
check "Tailscale installed" command_exists tailscale

# GPU is optional.
# If no NVIDIA GPU exists, do not fail the doctor check.
if has_nvidia_gpu; then
  pass "NVIDIA GPU detected"

  total=$((total + 1))
  score=$((score + 1))

  check "nvidia-smi works" command_exists nvidia-smi

  if command_exists docker && command_exists nvidia-smi; then
    echo
    echo "INFO  Docker GPU test is not run by default because it pulls a large CUDA image."
    echo "INFO  Manual test:"
    echo "      docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu24.04 nvidia-smi"
  fi
else
  optional_skip "NVIDIA GPU not detected"
  optional_skip "nvidia-smi not required"
fi

check "Azure Arc agent installed" command_exists azcmagent

if command_exists azcmagent; then
  check "Azure Arc status readable" azcmagent show
fi

echo
echo "Score: $score/$total"

if [ "$score" -eq "$total" ]; then
  echo "Overall Health: PASS"
else
  echo "Overall Health: REVIEW REQUIRED"
fi
