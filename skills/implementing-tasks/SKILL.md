---
name: implementing-tasks
description: Implements the tasks of a plan test-first, with a failing check before every task, dependency order respected, nothing built beyond the acceptance criteria, and a per-task RED/GREEN report. Use when the user asks to implement, build, or execute a plan, spec, PLAN.md, tasks.md, or task list, even when the changes look trivial or the user is in a hurry.
---

# Implementing tasks

Input: a plan with tasks, acceptance criteria, and dependency annotations
(each task marked independent or naming what it depends on). If there is
no plan, or a task has no acceptance criteria, stop and ask for them. Do
not invent them.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

Copy this checklist and track progress, one RED/GREEN pair per task:

```
- [ ] 1. Order the tasks by their dependencies
- [ ] 2. Per task: RED (check written and run, fails), then GREEN
- [ ] 3. Run the full suite once
- [ ] 4. Write the report
```

## Rule 1: RED before every task, no exceptions

For every task, before writing any implementation line: write the check
that proves the acceptance criterion, run it, and see it fail or error.
Only then write the minimal code to make it pass. The check and the code
go in separate steps. Never in the same edit or the same command.

A task whose tests say "manual invocation" still gets RED: run the exact
command before the code exists and record its error.

| Excuse | Reality |
|---|---|
| "Acceptance criteria already say what output to expect" | That is the oracle the check compares against, not a substitute for running it first. |
| "No time before the deadline" | The check takes seconds. Skipping it causes the rework. |
| "It's a 3-line file" | Trivial code breaks too. |
| "Tests and code in one go is faster" | Then nothing ever failed, so nothing was proven. |

**Red flags — you are about to violate this:**
- An implementation file exists for a task and no check has failed yet.
- One edit or command writes both the test and the code.
- Thinking "I'll verify manually after".
- Treating "manual invocation" as meaning no check runs first.

**Keep test output small, keep the exit status.** Run focused checks
inline with quiet flags, through `rtk` or `tail` when available. A pipe
into `tail` hides the exit code, so capture it:
`cmd > /tmp/out.log 2>&1; echo "exit=$?"; tail -n 20 /tmp/out.log`.
For the full suite or build: if the `delivery-economy-low` agent exists,
dispatch the run there and ask only for pass/fail, failing test names, and
the decisive error line. Otherwise run it inline with a minimal reporter.

## Rule 2: follow the dependency annotations

Start a dependent task only after every task it depends on has passed
GREEN. Tasks marked independent may run concurrently via subagents, but
each subagent dispatch costs roughly 25k tokens of fixed overhead. Run
trivial tasks (a few lines, one file) one after another in this context.
Dispatch in parallel only independent tasks that are each substantial.
Rule 1 applies to every task either way.

## Rule 3: build only what the acceptance criteria ask for

Implement the literal acceptance criteria. No extra flags, validation, or
defensive code they did not name. If something seems missing from the
criteria, report it under `Gaps`. Do not add it.

## Report

The report is this skill's output. Use exactly this shape. The heading,
the labels, and the fixed values stay in English, verbatim, in any
conversation language. Only `<...>` slots are free text. One `###` block
per task, in the order run.

```markdown
## Tasks implemented: <plan title>

### Task <id>: <title>
- RED: `<command>` -> <failing line>
- GREEN: `<command>` -> <passing line>
- Files: <path>, one per line
- Gaps: <missing criterion or open question> | none

- Suite: `<command>` -> pass | fail: <failing test names>
- Not done: <task id>: <reason>, one per line | none
```
