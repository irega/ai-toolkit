# Tier candidate rotation

## Source spec/plan

Chat design (bounded path, `superpowers:brainstorming`), approved 2026-09-14.
Request: `skills/delivery-workflow/references/contract.md` currently says to
"pick the first candidate compatible with the current runtime" from
`tiers.json`, and only move to another candidate on runtime error
(fallback). OpenCode's tiers list 2-3 candidates per tier, so today it
always uses the same first candidate. User wants deliberate rotation for
variety, decided per-invocation (not per-session), using uniform random
selection (no persistent round-robin state needed). Cross-runtime
invocation (switching between claude/codex/opencode mid-session) is
explicitly out of scope.

## Acceptance criteria

1. WHEN a phase starts and needs a tier's model for the current runtime,
   THEN the candidate is chosen uniformly at random from that tier's
   candidate list for that runtime (not always the first).
2. WHEN a chosen candidate errors at call time (rate limit, no credit,
   unavailable), THEN retry with another candidate from the same tier's
   list for that runtime, excluding the one that just failed.
3. WHEN no alternate candidate exists for that runtime after a failure,
   THEN surface the failure explicitly — never silently drop to a
   different tier.
4. WHEN a candidate is used (first pick or after retry), THEN it is
   recorded in the Engram checkpoint for that phase, along with any retry
   (existing requirement, unchanged).
5. WHEN a tier/runtime has only one candidate (Claude and Codex today),
   THEN behavior is unchanged — random selection over a list of one always
   picks that one.

## Risks

- None identified. This is a policy-text change to a markdown contract; no
  runtime code executes the "pick a candidate" logic today (it's an
  instruction each skill's agent follows), so there is no code path to
  break and no rollout risk.

## Tests

No automated test suite covers this file (it's a policy doc, not
executable code). Verification is manual, matched to acceptance criteria:

- AC1-3, AC5: re-read the edited `contract.md` tier section; confirm it
  describes random selection per invocation, fallback-on-error to a
  different candidate excluding the failed one, explicit surfacing when no
  alternate exists, and that single-candidate tiers are unaffected —  with
  no contradiction against the rest of the contract.
- AC4: confirm the existing "record which candidate was used" sentence is
  still present and unchanged in meaning.

## Tasks

1. Edit `skills/delivery-workflow/references/contract.md` tier section
   (lines ~9-18) to replace "pick the first candidate compatible with the
   current runtime" with random per-invocation selection, keeping the
   fallback-on-error and explicit-failure-surfacing rules. (independent)

No changes to `tiers.json` — its structure (list of candidates per tier per
runtime) already supports this; only the selection policy in `contract.md`
changes.
