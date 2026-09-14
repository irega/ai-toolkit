#!/usr/bin/env bash
set -euo pipefail

# Prints the servers in configs/mcp-servers.json as a table
# (name, type, command/url).

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/configs/mcp-servers.json"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }

printf "%-15s %-10s %s\n" "NAME" "TYPE" "COMMAND/URL"
for i in $(jq -r '.servers | keys[]' "$SRC"); do
  name=$(jq -r ".servers[$i].name" "$SRC")
  type=$(jq -r ".servers[$i].type" "$SRC")
  command_bin=$(jq -r ".servers[$i].command // empty" "$SRC")
  args=$(jq -r ".servers[$i].args[]? // empty" "$SRC" | tr '\n' ' ')
  url=$(jq -r ".servers[$i].url // empty" "$SRC")

  if [ -n "$url" ]; then
    target="$url"
  elif [ -n "$command_bin" ]; then
    target="$command_bin $args"
  else
    target="(none)"
  fi

  printf "%-15s %-10s %s\n" "$name" "$type" "$target"
done
