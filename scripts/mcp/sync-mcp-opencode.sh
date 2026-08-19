#!/usr/bin/env bash
set -euo pipefail

# Merges MCP servers from configs/mcp-servers.json into the "mcp" key of
# ~/.config/opencode/opencode.json. Only that key is touched — the rest of
# the file (permissions, agents, etc.) is preserved untouched. Backs up the
# existing file first. Injects env vars from .env.local if present.

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/configs/mcp-servers.json"
ENV_LOCAL="$REPO/.env.local"
DEST="$HOME/.config/opencode/opencode.json"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
command -v opencode &>/dev/null || { echo "ERROR: 'opencode' CLI not found"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }
[ -f "$DEST" ] || { mkdir -p "$(dirname "$DEST")"; echo '{}' > "$DEST"; }

fragment="{}"
for i in $(jq -r '.servers | keys[]' "$SRC"); do
  name=$(jq -r ".servers[$i].name" "$SRC")
  type=$(jq -r ".servers[$i].type" "$SRC")
  command_bin=$(jq -r ".servers[$i].command // empty" "$SRC")
  args_json=$(jq -c ".servers[$i].args // []" "$SRC")
  url=$(jq -r ".servers[$i].url // empty" "$SRC")
  env_keys=$(jq -r ".servers[$i].envKeys[]? // empty" "$SRC")

  env_json="{}"
  if [ -f "$ENV_LOCAL" ] && [ -n "$env_keys" ]; then
    while IFS= read -r key; do
      value=$(grep -m1 "^${key}=" "$ENV_LOCAL" 2>/dev/null | cut -d= -f2- | xargs || true)
      [ -n "$value" ] && env_json=$(jq -c --arg k "$key" --arg v "$value" '. + {($k): $v}' <<< "$env_json")
    done <<< "$env_keys"
  fi

  if [ "$type" = "remote" ]; then
    entry=$(jq -n --arg url "$url" '{type: "remote", url: $url, enabled: true}')
  else
    command_json=$(jq -n --arg cmd "$command_bin" --argjson args "$args_json" '[$cmd] + $args')
    entry=$(jq -n --argjson command "$command_json" --argjson env "$env_json" \
      'if ($env | length) > 0 then {type: "local", command: $command, environment: $env, enabled: true}
       else {type: "local", command: $command, enabled: true} end')
  fi

  fragment=$(jq --arg name "$name" --argjson entry "$entry" '. + {($name): $entry}' <<< "$fragment")
  echo "registered $name (opencode)"
done

BACKUP="$DEST.backup.$(date +%Y%m%d-%H%M%S)"
cp "$DEST" "$BACKUP"
echo "Backed up existing opencode.json to $BACKUP"

jq --argjson mcp "$fragment" '.mcp = ((.mcp // {}) + $mcp)' "$DEST" > "$DEST.tmp" && mv "$DEST.tmp" "$DEST"
echo "Synced opencode.json mcp key ($DEST) (existing unmanaged servers preserved)"
