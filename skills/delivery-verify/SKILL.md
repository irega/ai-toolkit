---
name: delivery-verify
description: Use when starting phase 4 of the delivery workflow (after delivery-implement, before delivery-pr), to run conformance checks, fresh-context reviews, select E2E evidence, and reconcile the spec with what was actually built.
---

# delivery-verify

Phase 4 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract). Reviews run at the `standard`
tier.

## Step 1: conformance

Run the repo's existing checks (lint, build, test suite) and compare the
diff against the discovery artifact's acceptance criteria one by one. This
phase does not implement fixes — see Step 4.

## Step 2: fresh-context reviews

Dispatch each of these as its own fresh-context pass (a subagent, or a
genuinely separate context if the runtime has no subagent support — never
the same context that just ran Step 1, it's already anchored on its own
conclusions): correctness/regression, simplicity/YAGNI, design/
maintainability, repository conventions, and security/reliability when the
change touches trust boundaries. Parallelize the dispatch when the runtime
supports it (e.g. Claude Code's Agent tool); run them one after another
with fresh context otherwise.

## Step 3: E2E evidence, in this order — stop at the first that covers the criterion

1. Existing repo E2E tests already covering the acceptance criterion.
2. Unit/integration/contract test evidence that demonstrates the same
   behavior, even without a full E2E test.
3. Playwright MCP — **only** for a user-flow acceptance criterion still
   uncovered after 1 and 2, and only for that criterion.

**Never run Playwright MCP as a default extra check.** "More evidence is
always better" is not a reason — it burns browser-session tokens for
coverage the existing tests already prove.

| Excuse | Reality |
|---|---|
| "It's a user-facing change, let's be thorough" | Thorough means checking whether 1 or 2 already cover it, not reaching for the heaviest tool by default. |
| "Playwright would double-confirm it" | Double-confirming a criterion 1/2 already covers is wasted tokens, not rigor. |

## Step 4: the gate — critical failures go back, not forward

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

## Step 5: spec reconciliation

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
