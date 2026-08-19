#!/usr/bin/env bash
set -euo pipefail

# Dispatcher: syncs configs/mcp-servers.json into whichever of
# claude/codex/opencode CLIs are installed. Each sub-script is standalone
# and can also be run directly.

REPO_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$REPO_SCRIPTS/../.." && pwd)"
ENV_LOCAL="$REPO/.env.local"
ZSHRC="$HOME/.zshrc"

ran_any=0
for tool in claude codex opencode; do
  if command -v "$tool" &>/dev/null; then
    bash "$REPO_SCRIPTS/sync-mcp-$tool.sh"
    ran_any=1
  else
    echo "Skipping $tool (CLI not found)"
  fi
done

[ "$ran_any" -eq 1 ] || echo "WARNING: none of claude/codex/opencode CLIs found, nothing synced"

# Export the Playwright MCP extension token into ~/.zshrc too — the Chrome
# extension reads it from the interactive shell environment, not from the
# MCP server registration. Idempotent: skips if already exported anywhere in
# .zshrc, and always reads the current value from .env.local rather than
# freezing it.
PLAYWRIGHT_KEY="PLAYWRIGHT_MCP_EXTENSION_TOKEN"
if [ -f "$ENV_LOCAL" ]; then
  value=$(grep -m1 "^${PLAYWRIGHT_KEY}=" "$ENV_LOCAL" 2>/dev/null | cut -d= -f2- | xargs || true)
  if [ -n "$value" ]; then
    [ -f "$ZSHRC" ] || touch "$ZSHRC"
    if grep -q "^export ${PLAYWRIGHT_KEY}=" "$ZSHRC" 2>/dev/null; then
      echo "~/.zshrc already exports $PLAYWRIGHT_KEY, skipping"
    else
      {
        echo ""
        echo "# $PLAYWRIGHT_KEY (ai-toolkit MCP env, synced from $ENV_LOCAL)"
        echo "export ${PLAYWRIGHT_KEY}=\"\$(grep -m1 '^${PLAYWRIGHT_KEY}=' \"$ENV_LOCAL\" 2>/dev/null | cut -d= -f2-)\""
      } >> "$ZSHRC"
      echo "Added $PLAYWRIGHT_KEY export to ~/.zshrc"
    fi
  fi
fi
