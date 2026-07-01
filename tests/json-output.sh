#!/usr/bin/env bash
set -Eeuo pipefail

output="$(./bootstrap.sh doctor --json || true)"

echo "$output" | grep -q '"overall_health"'
echo "$output" | grep -q '"required"'
echo "$output" | grep -q '"recommended"'
echo "$output" | grep -q '"optional"'
echo "$output" | grep -q '"results"'

echo "JSON output smoke test passed."
