#!/usr/bin/env bash
set -Eeuo pipefail

cat <<'TEXT'
Azure Arc Onboarding

Safe model:

1. Login interactively:

   az login --use-device-code

2. Use Azure Portal for beginner onboarding:

   Azure Arc -> Machines -> Add -> Single server -> Linux script

Never commit Azure secrets, tokens, or service principal passwords.
TEXT
