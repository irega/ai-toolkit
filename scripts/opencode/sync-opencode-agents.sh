#!/usr/bin/env bash
set -euo pipefail

# Generates one pinned OpenCode subagent per capability tier in
# skills/delivery-workflow/tiers.json, under ~/.config/opencode/agents/.
#
# OpenCode's task tool has no per-call model override (params.model isn't
# wired yet) — a subagent always inherits its agent's configured model, or
# the parent session's model if the agent doesn't set one. Pinning the model
# in the agent's frontmatter is the only mechanism that survives that gap.
#
# One candidate per tier is pinned (the first "opencode" entry in
# tiers.json), not every candidate — rotating across candidates would need
# one agent file per candidate and a generator kept in sync by hand for no
# runtime benefit here. Widen this only if per-candidate rotation is
# actually needed for OpenCode.

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/skills/delivery-workflow/tiers.json"
DEST="$HOME/.config/opencode/agents"

command -v jq &>/dev/null || { echo "ERROR: jq required. Install: brew install jq"; exit 1; }
[ -f "$SRC" ] || { echo "ERROR: $SRC not found"; exit 1; }

mkdir -p "$DEST"

for tier in $(jq -r '.tiers | keys[]' "$SRC"); do
  candidate=$(jq -r ".tiers[\"$tier\"].candidates.opencode[0] // empty" "$SRC")
  if [ -z "$candidate" ]; then
    echo "skipping $tier (no opencode candidate in tiers.json)"
    continue
  fi
  provider=$(jq -r ".tiers[\"$tier\"].candidates.opencode[0].provider" "$SRC")
  model=$(jq -r ".tiers[\"$tier\"].candidates.opencode[0].model" "$SRC")
  purpose=$(jq -r ".tiers[\"$tier\"].purpose" "$SRC")

  name="delivery-${tier//_/-}"
  target="$DEST/$name.md"

  cat > "$target" <<EOF
---
description: Pinned to the delivery-workflow "$tier" tier. $purpose
mode: subagent
model: $provider/$model
---

Follow the dispatching skill's instructions exactly (delivery-workflow
phase skill, or a task brief from superpowers:subagent-driven-development).
This agent exists only to pin the model for the "$tier" tier — it carries
no extra rules of its own.
EOF

  echo "generated $name -> $target ($provider/$model)"
done
