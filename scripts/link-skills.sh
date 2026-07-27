#!/usr/bin/env bash
set -euo pipefail

# Symlinks every skill in this repo's skills/ dir into ~/.claude/skills

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

find "$REPO/skills" -name SKILL.md -print0 |
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  target="$DEST/$name"

  [ -e "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
  ln -sfn "$src" "$target"
  echo "linked $name"
done
