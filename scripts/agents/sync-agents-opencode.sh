#!/usr/bin/env bash
set -euo pipefail

# Generates one pinned OpenCode subagent per (tier, effort) pair in
# skills/delivering-changes/tiers.json, under ~/.config/opencode/agents/.
#
# OpenCode's task tool has no per-call model override (params.model isn't
# wired yet) — a subagent always inherits its agent's configured model, or
# the parent session's model if the agent doesn't set one. Pinning in the
# agent's frontmatter is the only mechanism that survives that gap.
#
# Effort is pinned through `variant`, whose accepted values are defined by
# the model rather than by OpenCode, so it is emitted only for a candidate
# that declares a `variants` map in tiers.json. Where that map is missing,
# the agent still pins the model and this script says out loud that effort
# is NOT pinned — silently shipping an agent that looks effort-pinned but
# isn't is the failure mode this warning exists to prevent.
#
# Every candidate for a tier gets its own agent file, suffixed
# `--<model>` (delivery-standard-low--minimax-m3,
# delivery-standard-low--kimi-k2.7-code) whenever a tier lists more than one
# opencode candidate. A single-candidate tier keeps the plain
# delivery-<tier>-<effort> name. This is what makes the contract's "pick one
# candidate uniformly at random" rule possible for OpenCode: the dispatcher
# picks which agent *file* to call, since there is no per-call model
# override to pick a model after the fact.

source "$(dirname "$0")/lib.sh"
preflight

DEST="$HOME/.config/opencode/agents"
mkdir -p "$DEST"

generated=()

unpinned=()

for tier in $(tier_names); do
  count="$(candidate_count "$tier" opencode)"
  if [ "$count" -eq 0 ]; then
    echo "skipping $tier (no opencode candidate in tiers.json)"
    continue
  fi
  for effort in $(tier_efforts "$tier"); do
    for ((i = 0; i < count; i++)); do
      provider="$(candidate_field_at "$tier" opencode "$i" provider)"
      model="$(candidate_field_at "$tier" opencode "$i" model)"
      if [ "$count" -gt 1 ]; then
        name="$(agent_name "$tier" "$effort" "$model")"
      else
        name="$(agent_name "$tier" "$effort")"
      fi
      variant=$(jq -r --arg t "$tier" --arg e "$effort" --arg i "$i" \
        '.tiers[$t].candidates.opencode[($i|tonumber)].variants[$e] // empty' "$TIERS")

      if [ -n "$variant" ]; then
        variant_line="variant: $variant"
        note="variant=$variant"
      else
        variant_line="$DROP_MARKER"
        note="effort NOT pinned"
        unpinned+=("$name")
      fi

      render "$TEMPLATES/opencode.md" \
        NAME "$name" \
        DESCRIPTION "$(agent_description "$tier" "$effort")" \
        MODEL "$provider/$model" \
        VARIANT_LINE "$variant_line" \
        TIER "$tier" > "$DEST/$name.md"
      echo "generated $name -> $DEST/$name.md ($provider/$model, $note)"
      generated+=("$name")
    done
  done
done

if [ "${#unpinned[@]}" -gt 0 ]; then
  echo ""
  echo "WARNING: effort is not pinned for: ${unpinned[*]}"
  echo "    These agents pin the model only. They inherit the parent session's"
  echo "    effort, so a tier's effort split is advisory under OpenCode."
  echo "    To pin it, add a per-effort \"variants\" map to that tier's first"
  echo "    opencode candidate in skills/delivering-changes/tiers.json, using"
  echo "    the variant names the pinned model actually accepts, then re-run."
fi

report_stale "$DEST" md ${generated[@]+"${generated[@]}"}
