#!/usr/bin/env bash
set -euo pipefail

# Sync ~/.claude/settings.json from configs/claude/settings.json (repo is
# source of truth). Backs up the existing file before overwriting.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/configs/claude/settings.json"
DEST="$HOME/.claude/settings.json"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }

if [ -f "$DEST" ]; then
  BACKUP="$DEST.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$DEST" "$BACKUP"
  echo "Backed up existing settings.json to $BACKUP"
fi

cp "$SRC" "$DEST"
jq . "$DEST" > /dev/null
echo "Synced settings.json ($SRC -> $DEST)"
