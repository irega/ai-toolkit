---
name: delivery-verify
description: Use when starting phase 4 of the delivery workflow (after implementing-tasks, before delivery-pr), to run conformance checks, select E2E evidence, and reconcile the spec with what was actually built.
---

# delivery-verify

Phase 4 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract).

## Step 1: conformance — `delivery-economy-low`

Run the repo's existing checks (lint, build, test suite) and compare the
diff against the discovery artifact's acceptance criteria one by one. This
is a mechanical pass/fail check, not judgment — dispatch it to the
`delivery-economy-low` pinned agent, which returns the summary the
contract's "Dispatch cost" section defines, never the raw log. This phase
does not implement fixes — see Step 3.

**No repo checks to run → no dispatch.** If the repo has no lint, build, or
test suite, the only work left is comparing the diff against the
acceptance criteria. Do that inline and state in the phase report that no
repo checks exist. Do not pay a dispatch to discover there is nothing to
run.

## Step 2: E2E evidence for user-flow acceptance criteria — `delivery-standard-medium`

For each acceptance criterion that describes a user-facing flow:

1. **Existing repo E2E test already covers it** → use that, done — don't
   also run Playwright MCP for a criterion that's already covered.
2. **No E2E covers it** → run Playwright MCP for that specific criterion,
   even if unit/integration/contract tests already pass. Unit and
   integration tests prove the pieces work in isolation; they don't prove
   the real user-facing flow does, and that gap is exactly what E2E
   evidence exists to close.

Unit/integration/contract evidence is still useful and worth keeping, but
it isn't a substitute tier that lets you skip Playwright when no E2E exists
— it's what you had already, not what closes this gap.

**Never run Playwright MCP for a criterion an existing E2E test already
covers** — that's the actual waste (re-proving something already proven),
not running it when there's a real gap.

Non-user-flow acceptance criteria (internals, data shape, CLI output, pure
functions) never need Playwright MCP regardless of E2E coverage.

E2E runs and Playwright snapshots are noisy output. Report them as the
contract's "Dispatch cost" summary (pass/fail per criterion, the failing
step, the decisive error line), not as raw logs or full page snapshots.

## Step 3: the gate — critical failures go back, not forward — inline

The severity judgment already happened in Step 2 (each E2E result states
whether its criterion passed); this step applies the resulting verdicts,
it doesn't re-judge them. That is mechanical, so run it inline in
whichever context collected the verdicts — never as its own dispatch.

A critical failure is: an unmet acceptance criterion or a failing repo
check.

On a critical failure: **stop, do not implement the fix yourself, and
route back to `implementing-tasks`** with the specific failure named. Do
not pass it to `delivery-pr` with a note to fix later, and do not patch it
inline just because the fix looks small — that skips Step 1's repo checks
for the patched code, and blurs a phase boundary that exists so
implementation changes always go through `implementing-tasks`'s TDD
discipline.

**No exceptions:**
- "It's a one-line fix" doesn't move it into this phase.
- "We're almost done, ship it and fix in a follow-up" doesn't clear a
  critical failure — a follow-up is fine for non-critical findings only.

## Step 4: spec reconciliation — `delivery-high-reasoning-high`

Compare the source spec/plan, the final diff, the tests, and the E2E
evidence.

- **No divergence** → conformance holds.
- **Divergence that's an accepted behavior/design change** (prompted by the
  user or surfaced and accepted during review) → update the source spec
  artifact (the OpenSpec files, or whatever `planning-changes` produced)
  on the same branch, persist the decision in Engram, then repeat Step 1's
  conformance check against the updated spec.
- **Divergence that's just what the code happens to do** → this is a
  critical failure. Go to Step 3. Do not edit the spec to match it.

**Never edit the spec merely to justify divergent code.** The spec changes
only when a human or a review explicitly accepted the new behavior — never
as a shortcut to make conformance pass.

| Excuse | Reality |
|---|---|
| "The spec is basically what we built, close enough" | "Close enough" is the divergence. Either it was accepted (record it) or it's a critical failure (Step 3). |
| "Updating the spec is faster than reverting the code" | Speed isn't the test — whether a human/review actually accepted this behavior is. |

Internal refactors with no behavior change touch docs only if a technical
claim in them is now false — that's not reconciliation, just accuracy.
