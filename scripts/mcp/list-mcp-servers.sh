#!/usr/bin/env bash
set -euo pipefail

# Prints the servers defined in configs/mcp-servers.json as a table.

REPO_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$REPO_SCRIPTS/../.." && pwd)"
CONFIG="$REPO/configs/mcp-servers.json"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: $CONFIG not found" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed" >&2
  exit 1
fi

printf "%-15s %-8s %-10s %-40s %-25s\n" "NAME" "TYPE" "COMMAND" "ARGS" "ENV KEYS"
printf "%-15s %-8s %-10s %-40s %-25s\n" "----" "----" "-------" "----" "--------"

jq -r '
  .servers[]
  | [
      (.name // "-"),
      (.type // "-"),
      (.command // "-"),
      ((.args // []) | join(" ")),
      ((.envKeys // []) | join(","))
    ]
  | @tsv
' "$CONFIG" | while IFS=$'\t' read -r name type command args envKeys; do
  printf "%-15s %-8s %-10s %-40s %-25s\n" "$name" "$type" "$command" "${args:--}" "${envKeys:--}"
done
