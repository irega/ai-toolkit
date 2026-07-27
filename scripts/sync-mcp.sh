#!/usr/bin/env bash
set -euo pipefail

# Registers MCP servers from configs/claude/mcp.json with the `claude` CLI
# (user scope). Idempotent: removes before re-adding. Injects env vars from
# .env.local if present (see .env.example).

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/configs/claude/mcp.json"
ENV_LOCAL="$REPO/.env.local"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
command -v claude &>/dev/null || { echo "ERROR: 'claude' CLI not found"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }

for server in $(jq -r '.mcpServers | keys[]' "$SRC"); do
  command=$(jq -r ".mcpServers[\"$server\"].command" "$SRC")
  args=$(jq -r ".mcpServers[\"$server\"].args[]" "$SRC")

  env_flags=()
  if [ -f "$ENV_LOCAL" ]; then
    while IFS='=' read -r key value || [ -n "$key" ]; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      value=$(echo "$value" | xargs)
      [ -n "$value" ] && env_flags+=(-e "$key=$value")
    done < "$ENV_LOCAL"
  fi

  claude mcp remove "$server" --scope user 2>/dev/null || true
  claude mcp add "$server" --scope user ${env_flags[@]+"${env_flags[@]}"} -- $command $args
  echo "registered $server"
done
