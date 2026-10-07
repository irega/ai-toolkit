---
name: delivering-changes
description: Carries a change from request to draft pull requests as one orchestrated run (prepare, plan, implement, verify, review, open PRs), with gates that loop failures back to implementation. Use only when the user asks for the full end-to-end delivery workflow, or wants a change carried all the way to PRs in one run. Not for a single step such as only planning, only reviewing, or only opening a PR.
---

# Delivering changes

Orchestrator. Owns sequencing, gates, routing, tiers, and Engram
checkpoints. Each phase skill does its own work and returns a fixed-shape
output. Invoke it, read that output, enforce what happens between phases.
Never redo a phase's work here. Orchestration decisions run at the
`high_reasoning` tier. Tiers, pinned agents, and checkpoint cadence:
`references/contract.md`.

```
- [ ] 1. preparing-projects   -> read its report
- [ ] 2. planning-changes     -> read the artifact path
- [ ] 3. implementing-tasks   -> read the per-task report
- [ ] 4. verifying-changes    -> Verdict: PASS | FAIL | BLOCKED
- [ ] 5. reviewing-changes    -> Verdict: PASS | FAIL
- [ ] 6. opening-pull-requests -> read the per-PR result
```

## Phases

Run 1 to 5 inline: each is cheap to invoke, and 2 talks to the user.
`verifying-changes`, `reviewing-changes`, and `implementing-tasks`
dispatch their own subagents. **Dispatch step 6** to `delivery-economy-low`
if it exists (`--<model>` variants: pick one at random), else a generic
subagent, and record which one ran. Pass each phase what it needs: the
report or artifact path from the previous one.

Read each phase's fixed-shape output (`## Project prepared`,
`## Change planned` with `Artifact:`, `## Tasks implemented`,
`Verdict:`, `## Pull requests`). Do not re-derive it from the repo.

## Gates

- `verifying-changes` `FAIL`: route to `implementing-tasks` with each
  failure named. Never patch it here. `BLOCKED` (evidence missing): stop
  and ask the operator.
- `reviewing-changes` `FAIL`: route its critical findings to
  `implementing-tasks` the same way. Non-critical findings go into the PR
  body as follow-ups.
- Loop 3, 4, 5 until both verdicts are `PASS`. Only then run step 6.

## Run every phase, every time

Run all six phases for every request, including tiny ones. Size changes
effort, never which phases run. A user request to skip a phase does not
authorize it: say what is lost (no acceptance criteria to check, no fresh
review, no gate before the PR) and run it. To use a single phase, the user
invokes that skill directly, outside this workflow.

| Excuse | Reality |
|---|---|
| "It's trivial, skip planning" | Planning for a trivial change is a two-line artifact. Verification needs something to check against. |
| "I ran it by hand, that is verification" | That is verification outside the gate. Run it inside. |
| "The user told me to skip it" | Explain the trade-off and run it anyway. |
| "The PR dispatch hit a blocker, I'll finish it here" | Never inline a dispatched phase. Retry with the blocker's context, or escalate. |

**Red flags:** implementation code before an artifact exists; a PR opened
before both verdicts are `PASS`; the orchestrator running a dispatched
phase's commands itself.

## State

Save an Engram checkpoint at every phase transition and gate decision,
including each loop back to implementation. Record which agent ran each
dispatch. Another agent must resume from memory plus artifacts.
