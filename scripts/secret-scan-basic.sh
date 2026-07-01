#!/usr/bin/env bash
set -Eeuo pipefail

echo "Running basic secret scan..."

failed=0

patterns=(
  "BEGIN RSA PRIVATE KEY"
  "BEGIN OPENSSH PRIVATE KEY"
  "AZURE_CLIENT_SECRET=.*[A-Za-z0-9]"
  "TAILSCALE_AUTH_KEY=.*tskey"
  "GITHUB_TOKEN=.*ghp_"
  "password=.*[A-Za-z0-9]"
  "client_secret=.*[A-Za-z0-9]"
)

for pattern in "${patterns[@]}"; do
  if grep -RInE \
    --exclude-dir=.git \
    --exclude='secret-scan-basic.sh' \
    --exclude='.env.example' \
    --exclude='README.md' \
    "$pattern" .; then
    failed=1
  fi
done

if [ "$failed" -eq 1 ]; then
  echo "Potential secret found. Review before committing."
  exit 1
fi

echo "No obvious secrets found."
