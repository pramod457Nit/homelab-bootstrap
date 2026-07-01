#!/usr/bin/env bash
set -Eeuo pipefail

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
TEXT
