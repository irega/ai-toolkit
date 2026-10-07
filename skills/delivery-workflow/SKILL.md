---
name: delivery-workflow
description: Use when the user explicitly asks for the full delivery workflow, or asks to build/fix/change something and wants it carried through prepare, discovery, implementation, verification, and PR as one orchestrated run.
---

# delivery-workflow

Entrypoint and orchestrator (see `references/contract.md` for the phase
list, capability tiers, and Engram checkpoint cadence — this skill doesn't
restate them). Run orchestration decisions at the `high_reasoning` tier.

This skill owns sequencing and the gates between phases. It does not
restate any phase's internal rules — `preparing-projects`, `planning-changes`,
`implementing-tasks`, `delivery-verify`, `reviewing-changes`, and
`delivery-pr` each already carry their own tested rules; invoke them and
enforce what happens between them.

**Run `preparing-projects` inline** — it's a few detection commands, cheaper
than a dispatch's fixed overhead (see contract.md's "Dispatch cost").
**Dispatch `delivery-pr` as a subagent** at the tier its `SKILL.md`
declares (`economy`) — packaging is mechanical, with no need for this
session's own model. Run `planning-changes` inline — it needs to talk to
the human directly, a subagent can't relay that without adding a
round-trip. See `references/contract.md`'s Capability tiers section for
the fail-closed rule and the per-runtime dispatch mechanism (pinned
OpenCode agents, explicit model param elsewhere) before dispatching.

A blocker inside `delivery-pr` (tool auth failure,
missing CLI, etc.) is never a reason to keep going yourself, step by step,
in this orchestrating context — retry the dispatch with the blocker's
context added, re-dispatch fresh past it, or escalate to the operator per
that phase's own degrade rule. See contract.md's "Never inline, not even
after a blocker."

## Run every phase, every time — size changes effort, never which phases run

`preparing-projects` → `planning-changes` → `implementing-tasks` →
`delivery-verify` → `reviewing-changes` → `delivery-pr`, in order, for
every request this skill handles — including ones that look tiny.

**No exceptions:**
- "This is tiny, skip the ceremony" doesn't drop a phase. A one-file change
  still goes through discovery (even a two-line artifact), verify, and
  review (even one combined fresh-context pass) — those phases scale down
  in effort, they don't disappear.
- The user asking to skip phases doesn't authorize it either — say so and
  explain what's lost (no acceptance criteria to check against, no
  fresh-context review, no gate before the PR opens) instead of complying.

| Excuse | Reality |
|---|---|
| "It's a single trivial script, no design ambiguity" | Discovery for a trivial task is a two-line artifact, not zero artifacts — delivery-verify still needs something to check conformance against. |
| "Manually running it once is verification enough" | That's exactly `delivery-verify`'s Step 1, done outside the gate — do it inside the gate instead, it costs nothing extra. |
| "The user told me to skip it" | Explain the trade-off and do it anyway; a request to skip a gate isn't authorization to skip it. |

**Red flags — you're about to violate this:**
- Writing implementation code before `planning-changes` produced an
  artifact.
- Opening a PR without having run `delivery-verify` and
  `reviewing-changes` on this diff.
- Any PR you're about to open targets `main`/`master` directly instead of
  the integration branch this run is stacked on (see contract.md).

## The gates between delivery-verify, reviewing-changes, and delivery-pr

`delivery-verify` returns one of two things: conformance holds (proceed to
`reviewing-changes`), or a critical failure (route back to
`implementing-tasks` with the specific failure named — per
`delivery-verify`'s own rules, do not patch it here in the orchestrator and
do not forward it).

`reviewing-changes` returns `Verdict: PASS` (proceed to `delivery-pr`) or
`Verdict: FAIL` (route its critical findings back to `implementing-tasks`
the same way). Non-critical findings go into the PR body as follow-ups.

Loop `implementing-tasks` → `delivery-verify` → `reviewing-changes` until
both pass before ever invoking `delivery-pr`.

## State and continuity

Track which phase is active and the artifacts each phase produced — a
different agent resuming this run needs that from Engram checkpoints, not
from re-deriving it. Persist a checkpoint at every phase transition and
every gate decision (per `references/contract.md`), including a loop back
from `delivery-verify` or `reviewing-changes` to `implementing-tasks`.
