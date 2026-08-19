#!/usr/bin/env bash
set -euo pipefail

# Removes broken symlinks (dangling targets) from the Claude Code, Codex,
# and OpenCode skill directories.

DESTS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
)

for DEST in "${DESTS[@]}"; do
  [ -d "$DEST" ] || continue

  find "$DEST" -maxdepth 1 -type l -print0 |
  while IFS= read -r -d '' link; do
    if [ ! -e "$link" ]; then
      rm "$link"
      echo "unlinked $(basename "$link") (broken -> $(readlink "$link")) from $DEST"
    fi
  done
done
