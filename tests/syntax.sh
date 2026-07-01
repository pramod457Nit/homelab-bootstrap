#!/usr/bin/env bash
set -Eeuo pipefail

bash -n bootstrap.sh
find bootstrap lib scripts tests -name "*.sh" -print0 | xargs -0 -I{} bash -n {}

echo "Syntax checks passed."
