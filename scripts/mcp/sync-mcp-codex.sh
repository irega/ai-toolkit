#!/usr/bin/env bash
set -euo pipefail

# Registers MCP servers from configs/mcp-servers.json with the `codex` CLI.
# Idempotent: removes before re-adding. Only touches [mcp_servers.*] in
# ~/.codex/config.toml — never overwrites the file. Injects env vars from
# .env.local if present (see .env.example).

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/configs/mcp-servers.json"
ENV_LOCAL="$REPO/.env.local"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
command -v codex &>/dev/null || { echo "ERROR: 'codex' CLI not found"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }
SERVERS=$(bash "$REPO/scripts/mcp/expand-servers.sh" "$SRC" "$ENV_LOCAL")
desired_azure=$(jq -r '.servers[] | select(.name | startswith("azure-devops-")) | .name' <<< "$SERVERS")
registered_azure=$(codex mcp list --json | jq -r '
  if type == "array" then .[] | .name?
  elif type == "object" then keys[]
  else empty
  end
  | select(type == "string" and startswith("azure-devops-"))
')
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if ! grep -Fxq "$name" <<< "$desired_azure"; then
    codex mcp remove "$name" 2>/dev/null || true
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
      [ -n "$value" ] && env_flags+=(--env "$key=$value")
    done <<< "$env_keys"
  fi

  codex mcp remove "$name" 2>/dev/null || true
  if [ "$type" = "remote" ]; then
    codex mcp add "$name" --url "$url"
  else
    codex mcp add "$name" ${env_flags[@]+"${env_flags[@]}"} -- "$command_bin" $args
  fi
  echo "registered $name (codex)"
done
