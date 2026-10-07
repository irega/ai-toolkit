# Delivery workflow contract

Shared reference for every `delivery-*` skill and `preparing-projects`. Keep this
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
| `preparing-projects` | Inline (a few detection commands — cheaper than a dispatch's fixed overhead) | No — advisory only |
| `planning-changes` | Inline (brainstorming needs to talk to the human) | No — advisory only |
| `implementing-tasks` | Dispatched per its own Rule 2 | Yes, bounded (see "Interaction with subagent-driven-development" below) |
| `delivery-verify` | Dispatched per step, per its own Steps 1-2 | Yes, bounded (see below) |
| `reviewing-changes` | Dispatched, one fresh-context pass per lens or one combined pass (`standard` tier) | Yes |
| `delivery-pr` | Dispatched as a subagent by the orchestrator | Yes |

**Never inline, not even after a blocker.** For the four dispatchable
phases, the orchestrator dispatches a subagent and stays out of that
phase's actual work — diagnosing a failure, drafting the PR body, running
the push, resolving an auth/tooling blocker. Hitting a blocker mid-phase
(e.g. `gh`/host-CLI auth failure) is not authorization to take the rest of
the phase over inline: retry the dispatch with the blocker's context added,
or re-dispatch a fresh subagent past the blocker, or escalate to the
operator per that phase's own degrade rule (`delivery-pr`'s Rule 5, for
example). Silently continuing step-by-step in the orchestrator's own
context after one blocked dispatch attempt is the same fail-open failure
this section exists to prevent, whether the excuse is a missing config
file or "I already had the context loaded, easier to finish it myself."

For the four dispatchable phases, the orchestrator (or the phase itself, for
implement/verify/review's internal fan-out) picks one candidate compatible
with the current runtime uniformly at random from that tier's list (a
tier/runtime with a single candidate always picks that one).

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
- If the dispatch mechanism itself has no way to pin the model or the
  effort for the chosen candidate (e.g. a `task` tool with no per-call
  model parameter, and no pinned-agent config for that candidate either):
  **stop and report it** —
  present the operator's real options (create the pinned-agent config for
  this runtime; accept the session-model fallback but log it explicitly in
  the Engram checkpoint as a tier violation, not a success; use a different
  dispatch channel) and wait for a choice. Never inherit the session model
  in silence and call it done.

## Pinned agents: the only channel for effort

A tier fixes the model. Reasoning effort is a second, independent dial, and
**no runtime lets a skill set it on an ad-hoc dispatch**:

| Runtime | Dispatch call accepts | Effort pinnable via |
|---------|----------------------|---------------------|
| Claude Code | `subagent_type`, `model`, `prompt` — no effort argument | `effort:` in `~/.claude/agents/<name>.md` frontmatter |
| Codex | agent name — reasoning effort is not an argument | `model_reasoning_effort` in `~/.codex/agents/<name>.toml` |
| OpenCode | `task` tool has no per-call model override either | `model:` and `variant:` in `~/.config/opencode/agents/<name>.md` |

A subagent that isn't pinned inherits the session's effort, so telling a
skill to "review at low effort" does nothing unless it dispatches to an
agent that was defined ahead of time with that effort baked in.

So `tiers.json` declares, per tier, both the candidates **and** the
`efforts` that tier is dispatched at. Run `scripts/agents/sync-agents.sh`
(from this repo) to generate one pinned agent per (tier, effort, candidate)
combination for whichever CLIs are installed; the per-runtime scripts next
to it do one runtime each. Agents are named `delivery-<tier>-<effort>`, with
underscores in the tier becoming dashes:

| Agent | Tier | Effort |
|-------|------|--------|
| `delivery-high-reasoning-high` | `high_reasoning` | high |
| `delivery-standard-medium` | `standard` | medium |
| `delivery-standard-low` | `standard` | low |
| `delivery-economy-low` | `economy` | low |

**Claude and Codex** each have exactly one candidate per tier in
`tiers.json` today, so their agent names are never suffixed — the table
above is literal for them.

**OpenCode has no per-call model override** (its `task` tool always
inherits the calling agent's pinned model), so a single agent file can't
offer a choice at dispatch time the way `tiers.json`'s "pick uniformly at
random" rule assumes. To make that rule real for OpenCode, the generator
emits one agent file **per candidate**, suffixed `--<model>`, whenever a
tier lists more than one OpenCode candidate:

| Agent | Tier | Effort | Candidate |
|-------|------|--------|-----------|
| `delivery-standard-low--minimax-m3` | `standard` | low | `minimax-m3` |
| `delivery-standard-low--kimi-k2.7-code` | `standard` | low | `kimi-k2.7-code` |

For OpenCode, "picks one candidate ... uniformly at random from that tier's
list" (above) means: list the `delivery-<tier>-<effort>--*` agent files (or
read `tiers.json`'s candidate list directly) and choose which **file** to
dispatch to. A tier with a single OpenCode candidate keeps the plain
unsuffixed name, same as Claude/Codex.

Dispatch to that agent name instead of a generic subagent. Re-run the sync
script after editing `tiers.json` — the agent files are generated output,
never hand-edited, and they are rendered from the templates in
`scripts/agents/templates/` (one per runtime) rather than from strings
inside the generator.

Editing `tiers.json` (renaming a tier, dropping an effort) leaves the old
agent file behind — it isn't wrong on its own, it just no longer matches
anything the generator would produce, so a skill could still dispatch to
it with no way to tell it's stale. `scripts/agents/prune-agents.sh` removes
exactly that set — every `delivery-*` file across all three agent
directories that current `tiers.json` would not generate — regardless of
which CLIs are installed, since a leftover can outlive an uninstall. Run it
after editing `tiers.json`, the same way `unlink-skills.sh` is run after
removing a skill.

**OpenCode caveat.** Its `variant` values are defined by the model, not by
OpenCode, so the generator emits `variant:` only for a candidate that
declares a `variants` map in `tiers.json`. Without one it pins the model,
prints a warning naming every agent whose effort is unpinned, and that
tier's effort split is advisory under OpenCode — which is the fail-loud
behaviour this file asks for everywhere else, not a silent pass.

## Interaction with subagent-driven-development

`implementing-tasks`, `delivery-verify`, and `reviewing-changes` dispatch
subagents for individual tasks, checks, and reviews. Don't re-implement
model selection for those dispatches —
`superpowers:subagent-driven-development`'s own Model Selection section
already picks a model per task by complexity, and its "always specify the
model explicitly" rule already gives the same fail-closed guarantee this
file asks for elsewhere.

The two systems compose, they don't compete: this file's tier
(`standard` for implement and review, mixed per-step for verify) sets the
**pool** of candidates that phase may draw from; `subagent-driven-development`'s
complexity heuristic picks **which candidate in that pool**, and decides
when to escalate within it (e.g. fix-loop rounds 4-5). Neither system picks
a model outside the tier's candidate list for that phase.

| Tier | Efforts | Used by |
|------|---------|---------|
| `high_reasoning` | high | Orchestrator (scope, routing, spec reconciliation), discovery/planning |
| `standard` | low, medium | Implementation, fresh-context reviews |
| `economy` | low | Mechanical/cheap checks only — never substantive planning or review |

## Dispatch cost

Every subagent dispatch pays a fixed overhead of roughly 25k tokens (system
prompt, tool definitions, re-reading context) before it does any work. A
dispatch is worth it only when the work it takes off the caller's context
is bigger than that overhead, or when a fresh context is the point (an
independent review).

- **Small work stays inline.** A handful of commands, a trivial task, or
  applying verdicts that already exist costs less inline than dispatched.
  The phase skills name which steps run inline.
- **A small diff gets one review pass, not a fan-out.** See
  `reviewing-changes` Step 2 for the threshold.

**Noisy output, easy judgment.** Test suites, builds, linters, and E2E
runs print large logs whose interpretation is trivial (pass or fail, which
test, which line). Run them inline, redirect the output to a log file,
capture the exit status, and read back only: pass/fail, the names of
failing tests or checks, and the shortest decisive error line for each.
Never the raw log. A log file keeps the output out of context without a
dispatch's fixed overhead, so noisy runs are not a reason to dispatch.

## Phases

1. `preparing-projects` — detect project conventions (OpenSpec/SDD), index
   with CodeGraph, check RTK, recover Engram checkpoints. Its report feeds
   phase 2; the orchestrator saves the phase-transition checkpoint.
2. `planning-changes` — produce source spec/plan, acceptance criteria,
   risks, tests, tasks with dependencies.
3. `implementing-tasks` — strict TDD per independent deliverable, parallelize
   only independent tasks, apply Ponytail/YAGNI.
4. `delivery-verify` — run repo checks and acceptance/spec conformance;
   for user-flow criteria, use an existing repo E2E test if one covers it,
   otherwise run Playwright MCP for that criterion regardless of
   unit/integration coverage (unit/integration don't substitute for E2E on
   a user-flow criterion); critical failures return to `implementing-tasks`.
5. Spec reconciliation (inside verify) — compare source spec/plan, diff,
   tests, and E2E evidence; for an accepted behavior/design change, update
   the source spec artifact on the same branch and persist the decision in
   Engram before repeating conformance. Never edit specs merely to justify
   divergent code. Internal refactors touch docs only if a technical claim
   is now false.
6. `reviewing-changes` — fresh-context reviews (correctness, simplicity,
   design, conventions, security when a trust boundary is touched);
   critical findings return to `implementing-tasks`.
7. `delivery-pr` — enforce small PRs, English title/body/docs, `show-me`
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
