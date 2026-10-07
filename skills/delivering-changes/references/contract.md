# Delivering changes: reference

The orchestrator's reference for tiers, dispatch, phase outputs, and Engram
checkpoints. Phase skills are standalone and do not link here.

## Contents

- Tiers
- Dispatch
- Phase outputs
- Engram checkpoints

## Tiers

Tier candidates live in `tiers.json` at the skill root
(`skills/delivering-changes/tiers.json`), one level above this folder.
Never hard-code a provider or model name in a skill.

| Tier | Efforts | Used by |
|------|---------|---------|
| `high_reasoning` | high | Orchestrator (scope, routing, spec reconciliation), planning |
| `standard` | low, medium | Implementation, fresh-context reviews |
| `economy` | low | Opening PRs and other mechanical work, never planning or review |

A tier is enforceable only on a dispatch. Inline work runs on the session
model, so its tier is advisory.

| Phase | Runs as | Tier enforceable? |
|-------|---------|-------------------|
| `delivering-changes` (orchestrator) | Inline | No |
| `preparing-projects` | Inline | No |
| `planning-changes` | Inline (talks to the user) | No |
| `implementing-tasks` | Inline; its own Rule 2 decides subagents | Yes, for those dispatches |
| `verifying-changes` | Inline; dispatches Playwright MCP runs (`standard`) and doubtful judgments (`high_reasoning`) | Yes, for those dispatches |
| `reviewing-changes` | Inline; dispatches its review passes (`standard`) | Yes |
| `opening-pull-requests` | Dispatched by the orchestrator to `delivery-economy-low` | Yes |

## Dispatch

Dispatch to the pinned agent `delivery-<tier>-<effort>`, never a generic
subagent when the pinned one exists. With `--<model>` variants, pick one at
random. How the agents are generated: `scripts/agents/README.md`.

**Retry.** A candidate that errors at call time (rate limit, no credit,
unavailable): retry with another candidate of the same tier and runtime.
None left: report the failure. Never drop to another tier. Record the
agent used, and any retry, in the phase's Engram checkpoint.

**Fail closed.** Before the first dispatch of a run, stop and report to the
operator when:
- `tiers.json` is missing, unreadable, or lacks the needed tier or runtime.
- No channel pins the model and effort for the candidate. Offer the
  options: create the pinned agent; accept the session model and log it in
  Engram as a tier violation; use another dispatch channel. Wait for a
  choice. Never inherit the session model in silence.

**Never inline a dispatch, not even after a blocker.** This applies to
every dispatch in a run, whether the orchestrator or a phase skill made it.
A blocked subagent (auth failure, missing CLI, rate limit) does not
authorize finishing its work in this session. Retry it with the blocker's
context, or dispatch a fresh subagent, or apply the skill's own degrade
rule, or escalate to the operator. Finishing it here in silence breaks the
tier and is the fail-open failure this contract forbids.

## Phase outputs

| # | Skill | Output the orchestrator reads |
|---|-------|-------------------------------|
| 1 | `preparing-projects` | `## Project prepared` report |
| 2 | `planning-changes` | `## Change planned` report, `Artifact:` paths |
| 3 | `implementing-tasks` | `## Tasks implemented` per-task report |
| 4 | `verifying-changes` | `Verdict: PASS \| FAIL \| BLOCKED` |
| 5 | `reviewing-changes` | `Verdict: PASS \| FAIL`, per-lens findings |
| 6 | `opening-pull-requests` | `## Pull requests` per-PR result |

## Engram checkpoints

Save a recovery checkpoint, not every action, at: startup or context
recovery, decisions, discoveries, configuration changes, phase transitions,
gate decisions, test and check outcomes, accepted behavior changes,
blockers, and session close. Another agent must be able to resume from
memory plus artifacts alone.
