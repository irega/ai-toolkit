# Delivery workflow contract

Shared reference for every `delivery-*` skill and `prepare-project`. Keep this
file the single source of truth for phases, tiers, and Engram checkpoints —
individual skills link here instead of restating it.

## Capability tiers

Never hard-code a provider or model name inside a skill. Read tier candidates
from `tiers.json` (same directory, versioned) and pick the first candidate
compatible with the current runtime. If none are available, fall back through
the remaining candidates in order and record which one was used and why in
the Engram checkpoint for that phase (fallback evidence).

| Tier | Used by |
|------|---------|
| `high_reasoning` | Orchestrator: scope, routing, gate decisions, spec reconciliation |
| `standard` | Discovery and implementation work |
| `economy` | Reviewers, mechanical checks, single-dimension review passes |

## Phases

1. `prepare-project` — detect project conventions (OpenSpec/SDD), enable
   Caveman/RTK/CodeGraph if available, recover Engram checkpoints. Missing
   optional capabilities degrade with explicit evidence, never silently.
2. `delivery-discovery` — produce source spec/plan, acceptance criteria,
   risks, tests, tasks with dependencies.
3. `delivery-implement` — strict TDD per independent deliverable, parallelize
   only independent tasks, apply Ponytail/YAGNI. Record E2E-evidence
   requirements in task DoD; never run Playwright MCP in this phase.
4. `delivery-verify` — run repo checks and acceptance/spec conformance;
   fresh-context reviews (correctness, simplicity, design, conventions,
   security when relevant); select E2E evidence by hierarchy (existing repo
   E2E → unit/integration/contract evidence → Playwright MCP only for an
   uncovered user-flow criterion); critical failures return to
   `delivery-implement`.
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
