---
name: delivering-changes
description: Carries a change from request to draft pull requests as one orchestrated run (prepare, plan, implement, verify, review, open PRs), with gates that loop failures back to implementation. Use only when the user asks for the full end-to-end delivery workflow, or wants a change carried all the way to PRs in one run. Not for a single step such as only planning, only reviewing, or only opening a PR.
---

# Delivering changes

Orchestrator. Owns sequencing, gates, routing, tiers, and Engram
checkpoints. Each phase skill does its own work and returns a fixed-shape
output. Invoke it, read that output, enforce what happens between phases.
Never redo a phase's work here. Orchestration decisions run at the
`high_reasoning` tier. Tiers, dispatch rules, and checkpoints:
`references/contract.md`.

Per phase: invoke the skill, write its output, save a checkpoint.

```
- [ ] 1. preparing-projects    -> ## Project prepared       -> mem_save
- [ ] 2. planning-changes      -> ## Change planned         -> mem_save
- [ ] 3. implementing-tasks    -> ## Tasks implemented      -> mem_save
- [ ] 4. verifying-changes     -> ## Verification, Verdict: -> mem_save
- [ ] 5. reviewing-changes     -> ## Review, Verdict:       -> mem_save
- [ ] 6. opening-pull-requests -> ## Pull requests          -> mem_save
```

## Phases

Run steps 1 to 5 in this session, not as subagents. Step 1 is a few
commands. Step 2 talks to the user. Steps 3 to 5 decide their own
dispatches. Follow each skill's rules and do not wrap it in another
dispatch. **Dispatch step 6** to `delivery-economy-low`
if it exists (`--<model>` variants: pick one at random), else a generic
subagent, and record which one ran. The dispatch prompt passes context
only: the branch, the plan path, the verdicts, the follow-ups. Never add
commit message, trailer, or attribution instructions. The skill owns them.

A phase is done only when its fixed-shape output is written as a chat
message, in the skill's exact shape, before the next skill call. A phase
run inline still writes it. A `mem_save`, a passing command, or a summary
is not the output. No output, no next phase. Pass the next phase what it needs from that
output: the report or the `Artifact:` paths. Do not re-derive it from the
repo.

## Gates

- `verifying-changes` `FAIL`: route to `implementing-tasks` with each
  failure named. Never patch it here. `BLOCKED` (evidence missing): stop
  and ask the operator.
- `reviewing-changes` `FAIL`: route its critical findings to
  `implementing-tasks` the same way. Non-critical findings go into the PR
  body as follow-ups.
- A gate reads the `Verdict:` line. No line means the phase is not done:
  finish it, never infer the verdict from checks that passed.
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
| "The phase clearly passed, the report is a formality" | The report is the gate's input and the user's record. Write it. |
| "The subagent hit a blocker, I'll finish it here" | Never inline a dispatch, the orchestrator's or a phase skill's. Retry with the blocker's context, or escalate. |

**Red flags:** implementation code before an artifact exists; a next phase
started before the previous one wrote its output; a PR opened before both
`Verdict:` lines say `PASS`; this session doing the work of a blocked
subagent; commit or attribution instructions in a dispatch prompt.

## State

After each phase output and each gate decision, including each loop back
to implementation, call the Engram MCP tool `mem_save`. Title it
`Delivery <phase>: <change>`. The content holds the phase output's key
lines, the artifact paths, and which agent ran each dispatch. Another
agent must resume from memory plus artifacts. Engram unavailable: say so
once and continue.
