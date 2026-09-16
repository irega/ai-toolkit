# Delivery workflow contract

Shared reference for every `delivery-*` skill and `prepare-project`. Keep this
file the single source of truth for phases, tiers, and Engram checkpoints —
individual skills link here instead of restating it.

## Capability tiers

Never hard-code a provider or model name inside a skill. Read tier candidates
from `tiers.json` at the skill root — `skills/delivery-workflow/tiers.json`,
one level **above** this `references/` folder, not inside it.

**Which phases this applies to.** Only phases that actually get dispatched
as a subagent can have their tier enforced — a tier assignment on a phase
that runs inline, in whoever's context invoked it, is just a note to that
operator, not something any skill can pick or verify.

| Phase | Runs as | Tier enforceable? |
|-------|---------|--------------------|
| `delivery-workflow` (orchestrator) | Inline, in the invoking session | No — the operator's session model is the ceiling; this is advisory only |
| `prepare-project` | Dispatched as a subagent by the orchestrator | Yes |
| `delivery-discovery` | Inline (brainstorming needs to talk to the human) | No — advisory only |
| `delivery-implement` | Dispatched per task, per its own Rule 2 | Yes, bounded (see "Interaction with subagent-driven-development" below) |
| `delivery-verify` | Dispatched per step, per its own Steps 2-3 | Yes, bounded (see below) |
| `delivery-pr` | Dispatched as a subagent by the orchestrator | Yes |

For the four dispatchable phases, the orchestrator (or the phase itself, for
implement/verify's internal fan-out) picks one candidate compatible with the
current runtime uniformly at random from that tier's list (a tier/runtime
with a single candidate always picks that one).

If the chosen candidate errors at call time (rate limit, no credit,
unavailable), retry with another candidate in the same tier's list for that
runtime, excluding the model that just failed. If no alternate candidate
exists for that runtime, surface the failure explicitly — do not silently
drop to a different tier. Record which candidate was used, and any retry, in
the Engram checkpoint for that phase (fallback evidence).

**Fail closed, never silently.** Before the first dispatch of a run:
- If `tiers.json` is missing, unreadable, or has no entry for the needed
  tier/runtime: **stop and report it to the operator** — do not guess a
  model, do not fall back to the session's default, do not proceed on the
  assumption that "probably fine" covers a reasoning tier you can't verify.
- If the dispatch mechanism itself has no way to pin a model for the chosen
  candidate (e.g. a `task` tool with no per-call model parameter, and no
  pinned-agent config for that candidate either): **stop and report it** —
  present the operator's real options (create the pinned-agent config for
  this runtime; accept the session-model fallback but log it explicitly in
  the Engram checkpoint as a tier violation, not a success; use a different
  dispatch channel) and wait for a choice. Never inherit the session model
  in silence and call it done.

For OpenCode specifically: its `task` tool has no per-call model override
today, so the only working mechanism is a pinned subagent (`model:` in the
agent's frontmatter under `~/.config/opencode/agents/`). Run
`scripts/opencode/sync-opencode-agents.sh` (from this repo) to generate one
pinned agent per tier from `tiers.json`; dispatch to that agent's name
instead of a generic subagent when running under OpenCode.

## Interaction with subagent-driven-development

`delivery-implement` and `delivery-verify` dispatch subagents for individual
tasks and reviews. Don't re-implement model selection for those dispatches —
`superpowers:subagent-driven-development`'s own Model Selection section
already picks a model per task by complexity, and its "always specify the
model explicitly" rule already gives the same fail-closed guarantee this
file asks for elsewhere.

The two systems compose, they don't compete: this file's tier
(`standard` for implement, mixed per-step for verify) sets the **pool** of
candidates that phase may draw from; `subagent-driven-development`'s
complexity heuristic picks **which candidate in that pool**, and decides
when to escalate within it (e.g. fix-loop rounds 4-5). Neither system picks
a model outside the tier's candidate list for that phase.

| Tier | Used by |
|------|---------|
| `high_reasoning` | Orchestrator (scope, routing, spec reconciliation), discovery/planning, and fresh-context reviews |
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

## Commits

Every commit made during this workflow (any phase) uses Conventional
Commits format (`feat:`, `fix:`, `docs:`, `chore:`, ...) and carries no
AI/model attribution — no `Co-Authored-By` or similar trailer naming the
agent or model. Commits read as the human operator's own work.

## Engram checkpoints

Save a recovery checkpoint — not every action — at: startup/context
recovery, decisions, discoveries, configuration changes, phase transitions,
test/check outcomes, accepted behavior changes, blockers, and session close.
A different agent must be able to resume from memory plus artifacts alone.
