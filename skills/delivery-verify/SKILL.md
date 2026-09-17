---
name: delivery-verify
description: Use when starting phase 4 of the delivery workflow (after delivery-implement, before delivery-pr), to run conformance checks, fresh-context reviews, select E2E evidence, and reconcile the spec with what was actually built.
---

# delivery-verify

Phase 4 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract).

## Step 1: conformance — `economy` tier

Run the repo's existing checks (lint, build, test suite) and compare the
diff against the discovery artifact's acceptance criteria one by one. This
is a mechanical pass/fail check, not judgment — run it at the `economy`
tier. This phase does not implement fixes — see Step 4.

## Step 2: fresh-context reviews — `standard` tier

Dispatch each of these as its own fresh-context pass (a subagent, or a
genuinely separate context if the runtime has no subagent support — never
the same context that just ran Step 1, it's already anchored on its own
conclusions): correctness/regression, simplicity/YAGNI, design/
maintainability, repository conventions, and security/reliability when the
change touches trust boundaries. Parallelize the dispatch when the runtime
supports it (e.g. Claude Code's Agent tool); run them one after another
with fresh context otherwise. Use `low` reasoning effort for each pass
except correctness/regression, which stays at `medium` — these are diff
reviews against known acceptance criteria, not open-ended planning, so
`high_reasoning`'s heavier model is reserved for Step 5's spec
reconciliation instead. If a review's findings are ambiguous or contested,
re-dispatch that single pass at `high_reasoning` rather than raising the
tier for all four upfront.

## Step 3: E2E evidence for user-flow acceptance criteria — `standard` tier

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

## Step 4: the gate — critical failures go back, not forward — `standard` tier

The severity judgment already happened in Steps 2-3 (each review states
whether its findings are critical); this step applies the resulting
verdicts, it doesn't re-judge them.

A critical failure is: an unmet acceptance criterion, a failing repo check,
or a review finding severe enough that shipping it would be a regression.

On a critical failure: **stop, do not implement the fix yourself, and
route back to `delivery-implement`** with the specific failure named. Do
not pass it to `delivery-pr` with a note to fix later, and do not patch it
inline just because the fix looks small — that skips Step 1's repo checks
and Step 2's fresh-context reviews for the patched code, and blurs a phase
boundary that exists so implementation changes always go through
`delivery-implement`'s TDD discipline.

**No exceptions:**
- "It's a one-line fix" doesn't move it into this phase.
- "We're almost done, ship it and fix in a follow-up" doesn't clear a
  critical failure — a follow-up is fine for non-critical findings only.

## Step 5: spec reconciliation — `high_reasoning` tier

Compare the source spec/plan, the final diff, the tests, and the E2E
evidence.

- **No divergence** → conformance holds, proceed to `delivery-pr`.
- **Divergence that's an accepted behavior/design change** (prompted by the
  user or surfaced and accepted during review) → update the source spec
  artifact (the OpenSpec files, or whatever `delivery-discovery` produced)
  on the same branch, persist the decision in Engram, then repeat Step 1's
  conformance check against the updated spec.
- **Divergence that's just what the code happens to do** → this is a
  critical failure. Go to Step 4. Do not edit the spec to match it.

**Never edit the spec merely to justify divergent code.** The spec changes
only when a human or a review explicitly accepted the new behavior — never
as a shortcut to make conformance pass.

| Excuse | Reality |
|---|---|
| "The spec is basically what we built, close enough" | "Close enough" is the divergence. Either it was accepted (record it) or it's a critical failure (Step 4). |
| "Updating the spec is faster than reverting the code" | Speed isn't the test — whether a human/review actually accepted this behavior is. |

Internal refactors with no behavior change touch docs only if a technical
claim in them is now false — that's not reconciliation, just accuracy.
