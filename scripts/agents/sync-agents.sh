#!/usr/bin/env bash
set -euo pipefail

# Dispatcher: turns skills/delivering-changes/tiers.json into pinned subagents
# for whichever of claude/codex/opencode CLIs are installed. Each sub-script
# is standalone and can also be run directly.

REPO_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

ran_any=0
for tool in claude codex opencode; do
  if command -v "$tool" &>/dev/null; then
    bash "$REPO_SCRIPTS/sync-agents-$tool.sh"
    ran_any=1
  else
    echo "Skipping $tool (CLI not found)"
  fi
done

[ "$ran_any" -eq 1 ] || echo "WARNING: none of claude/codex/opencode CLIs found, no agents generated"
