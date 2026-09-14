# Delivery workflow contract

Shared reference for every `delivery-*` skill and `prepare-project`. Keep this
file the single source of truth for phases, tiers, and Engram checkpoints —
individual skills link here instead of restating it.

## Capability tiers

Never hard-code a provider or model name inside a skill. Read tier candidates
from `tiers.json` (same directory) and pick the first candidate compatible
with the current runtime.

If a candidate errors at call time (rate limit, no credit, unavailable),
retry with the next candidate in the same tier's list for that runtime,
excluding the model already used for this phase/task. If no alternate
candidate exists for that runtime, surface the failure explicitly — do not
silently drop to a different tier. Record which candidate was used, and any
retry, in the Engram checkpoint for that phase (fallback evidence).

| Tier | Used by |
|------|---------|
| `high_reasoning` | Orchestrator (scope, routing, gate decisions, spec reconciliation) and discovery/planning |
| `standard` | Implementation |
| `economy` | Mechanical/cheap checks only — never substantive planning or review |

## Phases

1. `prepare-project` — detect project conventions (OpenSpec/SDD), enable
   Caveman/RTK/CodeGraph if available, recover Engram checkpoints. Missing
   optional capabilities degrade with explicit evidence, never silently.
2. `delivery-discovery` — produce source spec/plan, acceptance criteria,
   risks, tests, tasks with dependencies.
3. `delivery-implement` — strict TDD per independent deliverable, parallelize
   only independent tasks, apply Ponytail/YAGNI.
4. `delivery-verify` — run repo checks and acceptance/spec conformance;
   fresh-context reviews (correctness, simplicity, design, conventions,
   security when relevant); for user-flow criteria, use an existing repo
   E2E test if one covers it, otherwise run Playwright MCP for that
   criterion regardless of unit/integration coverage (unit/integration
   don't substitute for E2E on a user-flow criterion); critical failures
   return to `delivery-implement`.
5. Spec reconciliation (inside verify) — compare source spec/plan, diff,
   tests, and E2E evidence; for an accepted behavior/design change, update
   the source spec artifact on the same branch and persist the decision in
   Engram before repeating conformance. Never edit specs merely to justify
   divergent code. Internal refactors touch docs only if a technical claim
   is now false.
6. `delivery-pr` — enforce small PRs, English title/body/docs, `show-me`
   only when a visual materially helps, open a **draft PR** once gates pass.

## Engram checkpoints

Save a recovery checkpoint — not every action — at: startup/context
recovery, decisions, discoveries, configuration changes, phase transitions,
test/check outcomes, accepted behavior changes, blockers, and session close.
A different agent must be able to resume from memory plus artifacts alone.
