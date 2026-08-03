#!/usr/bin/env bash
set -euo pipefail

# Removes broken symlinks (dangling targets) from ~/.claude/skills

DEST="$HOME/.claude/skills"

[ -d "$DEST" ] || exit 0

find "$DEST" -maxdepth 1 -type l -print0 |
while IFS= read -r -d '' link; do
  if [ ! -e "$link" ]; then
    rm "$link"
    echo "unlinked $(basename "$link") (broken -> $(readlink "$link"))"
  fi
done
