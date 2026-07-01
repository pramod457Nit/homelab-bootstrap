#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/common.sh"

json_mode=false
sudo_mode=false

for arg in "$@"; do
  case "$arg" in
    --json)
      json_mode=true
      ;;
    --sudo)
      sudo_mode=true
      ;;
    *)
      echo "Unknown doctor option: $arg" >&2
      exit 1
      ;;
  esac
done

if [ "$sudo_mode" = true ]; then
  sudo -v
fi

required_score=0
required_total=0
recommended_score=0
recommended_total=0
optional_score=0
optional_total=0
results=()

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

add_result() {
  local level="$1"
  local name="$2"
  local status="$3"

  results+=("{\"level\":\"$(json_escape "$level")\",\"name\":\"$(json_escape "$name")\",\"status\":\"$(json_escape "$status")\"}")
}

required_check() {
  local name="$1"
  shift

  required_total=$((required_total + 1))

  if "$@" >/dev/null 2>&1; then
    required_score=$((required_score + 1))
    add_result "required" "$name" "pass"
    if [ "$json_mode" = false ]; then
      pass "REQUIRED     $name"
    fi
  else
    add_result "required" "$name" "fail"
    if [ "$json_mode" = false ]; then
      fail "REQUIRED     $name"
    fi
  fi
}

recommended_check() {
  local name="$1"
  shift

  recommended_total=$((recommended_total + 1))

  if "$@" >/dev/null 2>&1; then
    recommended_score=$((recommended_score + 1))
    add_result "recommended" "$name" "pass"
    if [ "$json_mode" = false ]; then
      pass "RECOMMENDED  $name"
    fi
  else
    add_result "recommended" "$name" "warn"
    if [ "$json_mode" = false ]; then
      warn "RECOMMENDED  $name"
    fi
  fi
}

optional_check() {
  local name="$1"
  shift

  optional_total=$((optional_total + 1))

  if "$@" >/dev/null 2>&1; then
    optional_score=$((optional_score + 1))
    add_result "optional" "$name" "pass"
    if [ "$json_mode" = false ]; then
      pass "OPTIONAL     $name"
    fi
  else
    add_result "optional" "$name" "skip"
    if [ "$json_mode" = false ]; then
      skip "OPTIONAL     $name"
    fi
  fi
}

optional_skip() {
  local name="$1"

  optional_total=$((optional_total + 1))
  add_result "optional" "$name" "skip"

  if [ "$json_mode" = false ]; then
    skip "OPTIONAL     $name"
  fi
}

if [ "$json_mode" = false ]; then
  echo
  echo "homelab-bootstrap doctor"
  echo "========================"
  echo
  echo "Core OS"
  echo "-------"
fi

required_check "Ubuntu" is_ubuntu

if is_ubuntu && [ "$json_mode" = false ]; then
  version="$(ubuntu_version)"
  echo "INFO  Ubuntu version: $version"
fi

required_check "Git installed" command_exists git
required_check "Curl installed" command_exists curl
required_check "SSH service active" service_active ssh
required_check "UFW installed" command_exists ufw
required_check "Fail2Ban installed" command_exists fail2ban-client

if [ "$json_mode" = false ]; then
  echo
  echo "Container Runtime"
  echo "-----------------"
fi

recommended_check "Docker installed" command_exists docker
recommended_check "Docker service active" service_active docker

if command_exists docker; then
  recommended_check "Docker Compose installed" docker compose version
fi

if [ "$json_mode" = false ]; then
  echo
  echo "Remote Access"
  echo "-------------"
fi

recommended_check "Tailscale installed" command_exists tailscale
recommended_check "SSH restricted to Tailscale" ufw_ssh_restricted_to_tailscale

if [ "$json_mode" = false ]; then
  echo
  echo "Azure Hybrid"
  echo "------------"
fi

recommended_check "Azure Arc agent installed" command_exists azcmagent

if command_exists azcmagent; then
  recommended_check "Azure Arc status readable" azcmagent show
fi

if [ "$json_mode" = false ]; then
  echo
  echo "GPU / AI Workload"
  echo "-----------------"
fi

if has_nvidia_gpu; then
  optional_check "NVIDIA GPU detected" has_nvidia_gpu
  optional_check "nvidia-smi works" command_exists nvidia-smi

  if command_exists docker && command_exists nvidia-smi && [ "$json_mode" = false ]; then
    echo
    echo "INFO  Docker GPU test is not run by default because it pulls a large CUDA image."
    echo "INFO  Manual test:"
    echo "      homelab-bootstrap nvidia --container-test"
  fi
else
  optional_skip "NVIDIA GPU not detected"
  optional_skip "nvidia-smi not required"
fi

if [ "$required_score" -eq "$required_total" ]; then
  overall_health="pass"
else
  overall_health="fail"
fi

if [ "$json_mode" = true ]; then
  printf '{\n'
  printf '  "overall_health": "%s",\n' "$overall_health"
  printf '  "required": { "passed": %s, "total": %s },\n' "$required_score" "$required_total"
  printf '  "recommended": { "passed": %s, "total": %s },\n' "$recommended_score" "$recommended_total"
  printf '  "optional": { "passed": %s, "total": %s },\n' "$optional_score" "$optional_total"
  printf '  "results": [\n'

  for index in "${!results[@]}"; do
    if [ "$index" -gt 0 ]; then
      printf ',\n'
    fi
    printf '    %s' "${results[$index]}"
  done

  printf '\n  ]\n'
  printf '}\n'
else
  echo
  echo "Summary"
  echo "-------"
  echo "Required checks:    $required_score/$required_total"
  echo "Recommended checks: $recommended_score/$recommended_total"
  echo "Optional checks:    $optional_score/$optional_total"

  if [ "$overall_health" = "pass" ]; then
    echo "Overall Health: PASS"
  else
    echo "Overall Health: FAIL"
  fi

  if [ "$recommended_score" -lt "$recommended_total" ]; then
    echo "Recommendation: Some recommended hybrid features are missing."
  fi
fi

if [ "$overall_health" != "pass" ]; then
  exit 1
fi
