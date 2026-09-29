#!/usr/bin/env bash
set -euo pipefail

# Removes delivery-* pinned agents that the current tiers.json would not
# generate — leftovers from a renamed/removed tier, an old naming scheme,
# or a prior version of this repo. Companion to unlink-skills.sh, but an
# agent file isn't a symlink with an unambiguous "target missing" test, so
# staleness here is judged against tiers.json's current (tier, effort)
# pairs instead. Checks every known agent directory regardless of which
# CLIs are installed, since a leftover can outlive an uninstall.

source "$(dirname "$0")/lib.sh"
preflight

# runtime:dir:ext
TARGETS=(
  "claude:$HOME/.claude/agents:md"
  "codex:$HOME/.codex/agents:toml"
  "opencode:$HOME/.config/opencode/agents:md"
)

removed_any=0

for target in "${TARGETS[@]}"; do
  IFS=: read -r runtime dir ext <<<"$target"
  [ -d "$dir" ] || continue

  valid=" $(valid_agent_names "$runtime" | tr '\n' ' ') "

  for f in "$dir"/delivery-*."$ext"; do
    [ -e "$f" ] || continue
    base="$(basename "$f" ".$ext")"
    if [[ "$valid" != *" $base "* ]]; then
      rm "$f"
      echo "removed $base ($dir) — not in current tiers.json"
      removed_any=1
    fi
  done
done

[ "$removed_any" -eq 1 ] || echo "nothing stale, no agents removed"
