#!/usr/bin/env bash
set -Eeuo pipefail

cat <<'TEXT'
Azure Monitor

Recommended:
- Azure Arc-enabled server
- Azure Monitor Agent
- Data Collection Rule
- Log Analytics Workspace
- Alerts for heartbeat, CPU, disk, memory
TEXT
