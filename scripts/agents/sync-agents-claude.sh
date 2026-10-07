#!/usr/bin/env bash
set -euo pipefail

# Generates one pinned Claude Code subagent per (tier, effort) pair in
# skills/delivering-changes/tiers.json, under ~/.claude/agents/.
#
# Claude Code's Agent tool takes subagent_type, model and prompt — it has no
# effort parameter, and subagents otherwise inherit the session's effort
# level. The `effort` frontmatter field on a predefined subagent is the only
# channel that pins effort per dispatch.

source "$(dirname "$0")/lib.sh"
preflight

DEST="$HOME/.claude/agents"
mkdir -p "$DEST"

generated=()

for tier in $(tier_names); do
  model="$(candidate_field "$tier" claude model)"
  if [ -z "$model" ]; then
    echo "skipping $tier (no claude candidate in tiers.json)"
    continue
  fi
  for effort in $(tier_efforts "$tier"); do
    name="$(agent_name "$tier" "$effort")"
    render "$TEMPLATES/claude.md" \
      NAME "$name" \
      DESCRIPTION "$(agent_description "$tier" "$effort")" \
      MODEL "$model" \
      EFFORT "$effort" \
      TIER "$tier" > "$DEST/$name.md"
    echo "generated $name -> $DEST/$name.md ($model, effort=$effort)"
    generated+=("$name")
  done
done

report_stale "$DEST" md ${generated[@]+"${generated[@]}"}
