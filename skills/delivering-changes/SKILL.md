---
name: delivering-changes
description: Carries a change from request to draft pull requests as one orchestrated run (prepare, plan, implement, verify, review, open PRs), with gates that loop failures back to implementation. Use only when the user asks for the full end-to-end delivery workflow, or wants a change carried all the way to PRs in one run. Not for a single step such as only planning, only reviewing, or only opening a PR.
---

# Delivering changes

Orchestrator: owns sequencing, gates, tiers, and Engram checkpoints. Each
phase skill does its own work and returns a fixed-shape output. Never redo
a phase's work here. Tiers, dispatch rules, and checkpoints:
`references/contract.md`.

```
- [ ] 1. preparing-projects    -> ## Project prepared       -> mem_save
- [ ] 2. planning-changes      -> ## Change planned         -> mem_save
- [ ] 3. implementing-tasks    -> ## Tasks implemented      -> mem_save
- [ ] 4. verifying-changes     -> ## Verification, Verdict: -> mem_save
- [ ] 5. reviewing-changes     -> ## Review, Verdict:       -> mem_save
- [ ] 6. opening-pull-requests -> ## Pull requests          -> mem_save
```

## Phases

Run steps 1 to 5 in this session: 2 talks to the user, 3 to 5 decide their
own dispatches. **Dispatch step 6** to `delivery-economy-low` if it exists
(`--<model>` variants: pick one at random), else a generic subagent. Its
prompt passes context only (branch, plan path, verdicts, follow-ups),
never commit or attribution instructions.

A phase is done when its output, in the skill's exact shape, is in its
`mem_save`. A passing command or a summary is not the output. No output,
no next phase. Pass the next phase the report or `Artifact:` paths from
it; never re-derive them from the repo. The final message repeats every
output, in order.

## Gates

A gate reads the `Verdict:` line. No line: the phase is not done; never
infer a verdict from passing checks.

- Verify `FAIL` or review `FAIL`: route each failure or critical finding
  to `implementing-tasks`. Never patch it here.
- Verify `BLOCKED`: stop and ask the operator.
- Non-critical findings go into the PR body as follow-ups.
- Loop 3 to 5 until both verdicts are `PASS`. Only then run step 6.

## Every phase, every time

Size changes effort, never which phases run. A request to skip a phase
does not authorize it: say what is lost (acceptance criteria, fresh
review, the gate before the PR) and run it. A single phase is run by
invoking its skill directly, outside this workflow.

| Excuse | Reality |
|---|---|
| "It's trivial, skip planning" | A trivial plan is two lines. Verification needs it. |
| "I ran it by hand" | That is verification outside the gate. |
| "The user told me to skip it" | Explain the trade-off, run it anyway. |
| "The report is a formality" | It is the gate's input. Save it. |
| "The subagent is blocked, I'll finish it" | Never inline a dispatch. Retry with the blocker's context, or escalate. |

**Red flags:** code before a plan artifact; a phase started before the
previous one saved its output; a PR before both verdicts are `PASS`; this
session doing a blocked subagent's work; attribution in a dispatch prompt.

## State

After each phase and each gate decision, loops included, call the Engram
MCP tool `mem_save` titled `Delivery <phase>: <change>`, with the phase
output verbatim and the agent each dispatch ran on. Another agent must
resume from memory plus artifacts. Engram unavailable: say so once.
