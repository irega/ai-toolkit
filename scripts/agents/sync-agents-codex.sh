#!/usr/bin/env bash
set -euo pipefail

# Generates one pinned Codex subagent per (tier, effort) pair in
# skills/delivering-changes/tiers.json, under ~/.codex/agents/.
#
# Codex spawns subagents by name; reasoning effort is not an argument of that
# call. A custom agent TOML file may carry `model_reasoning_effort`, and a
# subagent that doesn't set one inherits the parent's effort — so pinning it
# in the file is the only channel that survives.

source "$(dirname "$0")/lib.sh"
preflight

DEST="$HOME/.codex/agents"
mkdir -p "$DEST"

generated=()

for tier in $(tier_names); do
  model="$(candidate_field "$tier" codex model)"
  if [ -z "$model" ]; then
    echo "skipping $tier (no codex candidate in tiers.json)"
    continue
  fi
  for effort in $(tier_efforts "$tier"); do
    name="$(agent_name "$tier" "$effort")"
    render "$TEMPLATES/codex.toml" \
      NAME "$name" \
      DESCRIPTION "$(toml_escape "$(agent_description "$tier" "$effort")")" \
      MODEL "$model" \
      EFFORT "$effort" \
      TIER "$tier" > "$DEST/$name.toml"
    echo "generated $name -> $DEST/$name.toml ($model, effort=$effort)"
    generated+=("$name")
  done
done

report_stale "$DEST" toml ${generated[@]+"${generated[@]}"}
