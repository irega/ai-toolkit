#!/usr/bin/env bash
set -euo pipefail

# Symlinks every skill in this repo's skills/ dir into the Claude Code,
# Codex, and OpenCode skill directories.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
)

for DEST in "${DESTS[@]}"; do
  mkdir -p "$DEST"

  find "$REPO/skills" -name SKILL.md -print0 |
  while IFS= read -r -d '' skill_md; do
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$DEST/$name"

    [ -e "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
    ln -sfn "$src" "$target"
    echo "linked $name -> $DEST"
  done
done
