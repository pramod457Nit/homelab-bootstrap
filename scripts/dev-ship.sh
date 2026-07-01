#!/usr/bin/env bash
set -Eeuo pipefail

MSG="${1:-}"

if [ -z "$MSG" ]; then
  echo "Usage:"
  echo "  scripts/dev-ship.sh \"commit message\""
  exit 2
fi

cd "$(git rev-parse --show-toplevel)"

if [ "$(git branch --show-current)" != "main" ]; then
  echo "[ERROR] Not on main branch"
  exit 1
fi

echo
echo "== Local checks =="
./bootstrap.sh doctor
bash tests/syntax.sh
bash tests/json-output.sh
bash scripts/secret-scan-basic.sh

echo
echo "== Git status =="
git status --short

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo
  echo "== Commit and push =="
  git add bootstrap.sh bootstrap scripts tests docs README.md install.sh .github 2>/dev/null || true
  git commit -m "$MSG"
  git push origin main
else
  echo "[INFO] No local changes to commit"
fi

echo
echo "== Update installed copy =="
curl -fsSL https://raw.githubusercontent.com/pramod457Nit/homelab-bootstrap/main/install.sh | bash

echo
echo "== Installed command verification =="
homelab-bootstrap doctor

if homelab-bootstrap help | grep -q "docker"; then
  homelab-bootstrap docker --verify
fi

if command -v nvidia-smi >/dev/null 2>&1 && homelab-bootstrap help | grep -q "nvidia"; then
  homelab-bootstrap nvidia --verify
fi

if command -v tailscale >/dev/null 2>&1 && homelab-bootstrap help | grep -q "tailscale"; then
  sudo -v
  homelab-bootstrap tailscale --verify
fi

if command -v azcmagent >/dev/null 2>&1 && homelab-bootstrap help | grep -q "azure-arc"; then
  homelab-bootstrap azure-arc --verify
fi

if homelab-bootstrap help | grep -q "azure-monitor"; then
  homelab-bootstrap azure-monitor --verify || true
fi

echo
echo "[PASS] Ship completed"
