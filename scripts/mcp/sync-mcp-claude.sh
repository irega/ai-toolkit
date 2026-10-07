#!/usr/bin/env bash
set -euo pipefail

# Registers MCP servers from configs/mcp-servers.json with the `claude` CLI
# (user scope). Idempotent: removes before re-adding. Injects env vars from
# .env.local if present (see .env.example).

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/configs/mcp-servers.json"
ENV_LOCAL="$REPO/.env.local"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
command -v claude &>/dev/null || { echo "ERROR: 'claude' CLI not found"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }
SERVERS=$(bash "$REPO/scripts/mcp/expand-servers.sh" "$SRC" "$ENV_LOCAL")
desired_azure=$(jq -r '.servers[] | select(.name | startswith("azure-devops-")) | .name' <<< "$SERVERS")
registered_azure=""
if [ -f "$HOME/.claude.json" ]; then
  registered_azure=$(jq -r '.mcpServers // {} | keys[]? | select(startswith("azure-devops-"))' "$HOME/.claude.json")
fi
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if ! grep -Fxq "$name" <<< "$desired_azure"; then
    claude mcp remove "$name" --scope user 2>/dev/null || true
  fi
done <<< "$registered_azure"

for i in $(jq -r '.servers | keys[]' <<< "$SERVERS"); do
  name=$(jq -r ".servers[$i].name" <<< "$SERVERS")
  type=$(jq -r ".servers[$i].type" <<< "$SERVERS")
  command_bin=$(jq -r ".servers[$i].command // empty" <<< "$SERVERS")
  args=$(jq -r ".servers[$i].args[]? // empty" <<< "$SERVERS")
  url=$(jq -r ".servers[$i].url // empty" <<< "$SERVERS")
  env_keys=$(jq -r ".servers[$i].envKeys[]? // empty" <<< "$SERVERS")

  env_flags=()
  if [ -f "$ENV_LOCAL" ] && [ -n "$env_keys" ]; then
    while IFS= read -r key; do
      value=$(grep -m1 "^${key}=" "$ENV_LOCAL" 2>/dev/null | cut -d= -f2- | xargs || true)
      [ -n "$value" ] && env_flags+=(-e "$key=$value")
    done <<< "$env_keys"
  fi

  claude mcp remove "$name" --scope user 2>/dev/null || true
  if [ "$type" = "remote" ]; then
    claude mcp add "$name" --scope user --transport http "$url"
  else
    claude mcp add "$name" --scope user ${env_flags[@]+"${env_flags[@]}"} -- "$command_bin" $args
  fi
  echo "registered $name (claude)"
done
