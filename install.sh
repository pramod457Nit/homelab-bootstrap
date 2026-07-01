#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${HOMELAB_BOOTSTRAP_REPO:-https://github.com/pramod457Nit/homelab-bootstrap.git}"
INSTALL_DIR="${HOMELAB_BOOTSTRAP_DIR:-$HOME/.local/share/homelab-bootstrap}"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/homelab-bootstrap"

echo "homelab-bootstrap installer"
echo "Repository: $REPO_URL"
echo "Install dir: $INSTALL_DIR"
echo

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is required."
  echo "Install it with:"
  echo "  sudo apt update && sudo apt install -y git"
  exit 1
fi

mkdir -p "$BIN_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Cloning repository..."
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/bootstrap.sh"
ln -sf "$INSTALL_DIR/bootstrap.sh" "$BIN_PATH"

echo
echo "Installed command:"
echo "  $BIN_PATH"
echo

if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  echo "NOTE: $BIN_DIR is not in your PATH."
  echo "Add this to your shell profile:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo
fi

echo "Running doctor..."
"$INSTALL_DIR/bootstrap.sh" doctor || true

echo
echo "Done."
echo
echo "Try:"
echo "  homelab-bootstrap doctor"
echo "  homelab-bootstrap doctor --json"
echo "  homelab-bootstrap security --dry-run"
