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

files=()

should_skip_file() {
  local file="$1"

  case "$file" in
    scripts/secret-scan-basic.sh) return 0 ;;
    .env.example) return 0 ;;
    README.md) return 0 ;;
    docs/*) return 0 ;;
    *) return 1 ;;
  esac
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    [ -f "$file" ] || continue
    should_skip_file "$file" && continue
    files+=("$file")
  done < <(git ls-files --cached --others --exclude-standard -z)
else
  while IFS= read -r -d '' file; do
    file="${file#./}"
    should_skip_file "$file" && continue
    files+=("$file")
  done < <(find . -type f \
    -not -path './.git/*' \
    -not -path './backups/*' \
    -not -path './snapshots/*' \
    -not -path './logs/*' \
    -print0)
fi

for pattern in "${patterns[@]}"; do
  for file in "${files[@]}"; do
    if grep -IInE "$pattern" "$file"; then
      failed=1
    fi
  done
done

if [ "$failed" -eq 1 ]; then
  echo "Potential secret found. Review before committing."
  exit 1
fi

echo "No obvious secrets found."
