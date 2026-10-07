#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home"

cat > "$TMP_DIR/config.json" <<'JSON'
{"servers":[{"name":"azure-devops","type":"local","command":"npx","args":["-y","@azure-devops/mcp","${org}","--authentication","azcli"],"organizationsEnv":"AZURE_DEVOPS_ORGS"},{"name":"static","type":"local","command":"npx","args":["static"]}]}
JSON
printf 'AZURE_DEVOPS_ORGS="org-a, org-b"\n' > "$TMP_DIR/.env.local"
bash "$REPO/scripts/mcp/expand-servers.sh" "$TMP_DIR/config.json" "$TMP_DIR/.env.local" > "$TMP_DIR/expanded.json"
jq -e '[.servers[].name] == ["azure-devops-org-a","azure-devops-org-b","static"] and .servers[0].args[2] == "org-a" and .servers[1].args[2] == "org-b"' "$TMP_DIR/expanded.json" >/dev/null

env -u AZURE_DEVOPS_ORGS bash "$REPO/scripts/mcp/expand-servers.sh" "$REPO/configs/mcp-servers.json" "$TMP_DIR/missing.env" > "$TMP_DIR/without-orgs.json" 2> "$TMP_DIR/warning.log"
jq -e '[.servers[].name] == ["playwright"]' "$TMP_DIR/without-orgs.json" >/dev/null
grep -q AZURE_DEVOPS_ORGS "$TMP_DIR/warning.log"

cat > "$TMP_DIR/bin/fake-cli" <<'SH'
#!/usr/bin/env bash
if [[ "$(basename "$0")" == codex && "$*" == "mcp list --json" ]]; then
  printf '[{"name":"azure-devops-org-a"},{"name":"azure-devops-stale"},{"name":"playwright"}]\n'
  exit 0
fi
printf '%s %s\n' "$(basename "$0")" "$*" >> "$MCP_SYNC_LOG"
SH
chmod +x "$TMP_DIR/bin/fake-cli"
ln -s "$TMP_DIR/bin/fake-cli" "$TMP_DIR/bin/codex"
ln -s "$TMP_DIR/bin/fake-cli" "$TMP_DIR/bin/claude"
ln -s "$TMP_DIR/bin/fake-cli" "$TMP_DIR/bin/opencode"
export HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:$PATH" MCP_SYNC_LOG="$TMP_DIR/registrations.log"
export AZURE_DEVOPS_ORGS='org-a,org-b'
printf '{"mcpServers":{"azure-devops-org-a":{},"azure-devops-stale":{},"unmanaged":{}}}\n' > "$HOME/.claude.json"
mkdir -p "$HOME/.config/opencode"
printf '{"mcp":{"azure-devops-org-a":{"command":[]},"azure-devops-stale":{"command":[]},"unmanaged":{"command":[]}}}\n' > "$HOME/.config/opencode/opencode.json"

bash "$REPO/scripts/mcp/sync-mcp-codex.sh" >/dev/null
bash "$REPO/scripts/mcp/sync-mcp-claude.sh" >/dev/null
bash "$REPO/scripts/mcp/sync-mcp-opencode.sh" >/dev/null
for agent in codex claude; do
  grep -q "$agent mcp add azure-devops-org-a .*@azure-devops/mcp org-a" "$MCP_SYNC_LOG"
  grep -q "$agent mcp add azure-devops-org-b .*@azure-devops/mcp org-b" "$MCP_SYNC_LOG"
  grep -q "$agent mcp remove azure-devops-stale" "$MCP_SYNC_LOG"
done
jq -e '
  .mcp["azure-devops-org-a"].command == ["npx", "-y", "@azure-devops/mcp", "org-a", "--authentication", "azcli"] and
  .mcp["azure-devops-org-b"].command == ["npx", "-y", "@azure-devops/mcp", "org-b", "--authentication", "azcli"] and
  (.mcp | has("azure-devops-stale") | not) and
  (.mcp | has("unmanaged"))
' "$HOME/.config/opencode/opencode.json" >/dev/null

echo "Azure DevOps org expansion and all-agent sync passed"
