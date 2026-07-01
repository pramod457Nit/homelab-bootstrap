#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
ACTION="${1:-help}"
shift || true

ADD_CURRENT_USER="false"

for arg in "$@"; do
  case "$arg" in
    --add-current-user)
      ADD_CURRENT_USER="true"
      ;;
    *)
      echo "[ERROR] Unknown option: $arg"
      exit 1
      ;;
  esac
done

title() {
  printf '\n%s\n' "homelab-bootstrap docker"
  printf '%s\n\n' "========================"
}

info() {
  printf '[INFO] %s\n' "$*"
}

ok() {
  printf '[PASS] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

docker_cli_installed() {
  has_cmd docker
}

docker_compose_installed() {
  docker compose version >/dev/null 2>&1
}

docker_service_active() {
  systemctl is-active --quiet docker 2>/dev/null
}

user_in_docker_group() {
  id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker
}

show_help() {
  cat <<'HELP'
Usage:
  ./bootstrap.sh docker --dry-run
  ./bootstrap.sh docker --apply
  ./bootstrap.sh docker --verify
  ./bootstrap.sh docker --apply --add-current-user

What it does:
  --dry-run             Show what would happen
  --apply               Install/enable Docker Engine if missing
  --verify              Verify Docker CLI, Compose plugin, and daemon
  --add-current-user    Optional: add current user to docker group

Security note:
  The docker group is root-equivalent. Do not add users blindly.
HELP
}

show_status() {
  title

  if docker_cli_installed; then
    ok "Docker CLI installed: $(docker --version)"
  else
    warn "Docker CLI not installed"
  fi

  if docker_compose_installed; then
    ok "Docker Compose plugin installed: $(docker compose version)"
  else
    warn "Docker Compose plugin not installed"
  fi

  if docker_service_active; then
    ok "Docker service active"
  else
    warn "Docker service not active"
  fi

  if [ -f /etc/apt/keyrings/docker.asc ]; then
    ok "Docker apt key exists"
  else
    warn "Docker apt key missing"
  fi

  if [ -f /etc/apt/sources.list.d/docker.sources ]; then
    ok "Docker apt source exists"
  else
    warn "Docker apt source missing"
  fi

  if getent group docker >/dev/null 2>&1; then
    ok "docker group exists"
  else
    warn "docker group missing"
  fi

  if user_in_docker_group; then
    ok "User '$TARGET_USER' is in docker group"
  else
    warn "User '$TARGET_USER' is not in docker group"
  fi
}

dry_run() {
  show_status

  echo
  info "Dry run only. No changes applied."
  echo
  echo "Would do:"
  echo "  1. Install required apt prerequisites"
  echo "  2. Add Docker official Ubuntu apt repository if needed"
  echo "  3. Install Docker Engine packages if missing"
  echo "  4. Enable and start docker.service"
  echo "  5. Verify Docker CLI, Docker Compose, and daemon"

  if [ "$ADD_CURRENT_USER" = "true" ]; then
    echo "  6. Add user '$TARGET_USER' to docker group"
  else
    echo "  6. Not adding user to docker group unless --add-current-user is used"
  fi
}

ensure_docker_repo() {
  info "Ensuring Docker official apt repository is configured..."

  # Remove older/conflicting Docker apt source formats before apt-get update.
  # Apt fails if the same Docker repo exists with different Signed-By values.
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/sources.list.d/docker.sources
  sudo rm -f /etc/apt/keyrings/docker.gpg
  sudo rm -f /etc/apt/keyrings/docker.asc

  sudo apt-get update
  sudo apt-get install -y ca-certificates curl

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
  ARCH="$(dpkg --print-architecture)"

  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt-get update
}

install_docker() {
  sudo -v

  ensure_docker_repo

  info "Installing or confirming Docker Engine packages..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  info "Enabling Docker service..."
  sudo systemctl enable --now docker

  if [ "$ADD_CURRENT_USER" = "true" ]; then
    warn "Adding '$TARGET_USER' to docker group. This is root-equivalent access."
    sudo groupadd -f docker
    sudo usermod -aG docker "$TARGET_USER"
    warn "Log out and log back in, or run: newgrp docker"
  else
    if ! user_in_docker_group; then
      warn "User '$TARGET_USER' is not in docker group."
      warn "Optional command:"
      warn "  ./bootstrap.sh docker --apply --add-current-user"
    fi
  fi
}

verify_docker() {
  title

  if docker_cli_installed; then
    ok "Docker CLI installed: $(docker --version)"
  else
    fail "Docker CLI missing"
    exit 1
  fi

  if docker_compose_installed; then
    ok "Docker Compose plugin installed: $(docker compose version)"
  else
    fail "Docker Compose plugin missing"
    exit 1
  fi

  if docker_service_active; then
    ok "Docker service active"
  else
    fail "Docker service not active"
    exit 1
  fi

  if sudo docker version >/dev/null 2>&1; then
    ok "Docker daemon reachable with sudo"
  else
    fail "Docker daemon not reachable"
    exit 1
  fi

  info "No container image was pulled. Run hello-world manually if needed:"
  info "  sudo docker run --rm hello-world"
}

case "$ACTION" in
  help|-h|--help)
    show_help
    ;;
  --dry-run)
    dry_run
    ;;
  --apply)
    install_docker
    verify_docker
    ;;
  --verify)
    verify_docker
    ;;
  *)
    fail "Unknown docker action: $ACTION"
    show_help
    exit 1
    ;;
esac
