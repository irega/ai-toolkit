---
name: implementing-tasks
description: Implements the tasks of a plan test-first, in dependency order, within the acceptance criteria, with a per-task RED/GREEN report. Use when the user asks to implement, build, or execute a plan, spec, PLAN.md, tasks.md, or task list, even when the changes look trivial or the user is in a hurry.
---

# Implementing tasks

Input: a plan whose tasks have acceptance criteria and are marked
independent or name what they depend on. No plan, or a task without
acceptance criteria: stop and ask. Do not invent them.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

```
- [ ] 1. Order the tasks by their dependencies
- [ ] 2. Per task: RED (check written and run, fails), then GREEN
- [ ] 3. Run the full suite once
- [ ] 4. Write the report
```

## Rule 1: RED before every task, no exceptions

Before any implementation line: write the check for the acceptance
criterion, run it, see it fail. Then write the minimal code to pass. The
check and the code go in separate steps, never in one edit or command.
"Manual invocation" tests still get RED: run the exact command before the
code exists and record its error.

| Excuse | Reality |
|---|---|
| "The criteria already say the expected output" | That is the oracle, not a substitute for running the check first. |
| "No time before the deadline" | The check takes seconds. Skipping it causes the rework. |
| "It's a 3-line file" | Trivial code breaks too. |
| "Tests and code in one go is faster" | Then nothing failed, so nothing was proven. |

**Red flags:**
- An implementation file exists and no check has failed yet.
- One edit or command writes both the test and the code.
- "I'll verify manually after."

**Small output, real exit status.** Every test, suite, or build run,
focused or full, goes to a log file. Read back only the summary and the
decisive error line. A pipe into `tail` hides the exit code, so capture it:
`cmd > "$TMPDIR/out.log" 2>&1; echo "exit=$?"; tail -n 20 "$TMPDIR/out.log"`.

## Rule 2: follow the dependency annotations

Start a dependent task only after all its dependencies passed GREEN. A
subagent costs roughly 25k tokens of fixed overhead, so use parallel
subagents only when 2 or more independent tasks are ready at once and each
is expected to change about 150 lines or more, tests included. Run every
other task in sequence here.

Dispatch to the `delivery-standard-medium` agent if it exists (with
`delivery-standard-medium--<model>` variants, pick one at random).
Otherwise use a generic subagent, which inherits this session's model.

## Rule 3: build only what the acceptance criteria ask for

Before each GREEN, check every line you added against the acceptance
criteria. A line is extra when no criterion or test needs it: a parameter,
option, flag, branch, validation, fallback, error handler, or abstraction
the criteria do not mention. Delete extra lines. If one seems necessary,
report it under `Gaps` instead of keeping it.

## Report

Use exactly this shape. The heading, the labels, and the fixed values stay
in English, verbatim, in any conversation language. Only `<...>` slots are
free text. One `###` block per task, in the order run.

```markdown
## Tasks implemented: <plan title>

### Task <id>: <title>
- RED: `<command>` -> <failing line>
- GREEN: `<command>` -> <passing line>
- Files: <path>, one per line
- Gaps: <missing criterion or open question> | none

- Suite: `<command>` -> pass | fail: <failing test names>
- Not done: <task id>: <reason>, one per line | none
- Dispatch: none | <agent name> | generic subagent (model unpinned)
```
