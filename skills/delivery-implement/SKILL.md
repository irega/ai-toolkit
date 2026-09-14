---
name: delivery-implement
description: Use when starting phase 3 of the delivery workflow (after delivery-discovery, before delivery-verify), to build the tasks in a discovery artifact under strict TDD without over-scoping.
---

# delivery-implement

Phase 3 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract). Run this phase at the `standard`
tier. Input is the discovery artifact `delivery-discovery` produced — its
tasks list is authoritative for scope and dependencies.

**REQUIRED BACKGROUND:** superpowers:test-driven-development.

## Rule 1: RED before every task, no exceptions

For every task, before writing any implementation line: write the check
that proves the acceptance criterion, and run it to confirm it fails or
errors first. Only then write the minimal code to make it pass.

This applies even when the artifact's "Tests" section says "manual
invocation" — that names the test *type*, not permission to skip running
it before the code exists. Write the exact manual command, run it against
the not-yet-existing behavior (it should fail/error), then implement.

**No exceptions:**
- Deadline or time pressure doesn't move this earlier or later.
- "The task is trivial" doesn't skip it — trivial code breaks too, and the
  check costs seconds.
- "I'll verify manually after" is tests-after, which proves the code does
  *something*, not that it does what was asked. Write the check first.

| Excuse | Reality |
|---|---|
| "Acceptance criteria already says what output to expect" | That's the oracle the check compares against, not a substitute for running the check before the code exists. |
| "No time before the deadline" | Writing the check first takes seconds; skipping it is what causes rework when the deadline hits. |
| "It's a 3-line file" | Trivial code breaks too. |

**Red flags — you're about to violate this:**
- An implementation file exists for a task and no check has been run yet.
- Thinking "I'll verify manually after" before any code is written.
- Treating "manual invocation" in the artifact as meaning no check runs first.

## Rule 2: parallelize only what the artifact marked independent

Read the task list's dependency annotations. Start a dependent task only
after every task it depends on is done and its checks pass. For tasks
marked independent, dispatch them concurrently via subagents when the
runtime supports it (e.g. Claude Code's Agent tool); run them one after
another when it doesn't. Either way, Rule 1 applies per task regardless of
whether it ran in parallel or sequentially.

## Rule 3: build only what the acceptance criteria ask for

Ponytail/YAGNI: implement the literal acceptance criteria, nothing added on
top (no extra flags, validation, or defensive code the criteria didn't
name). If you believe something is genuinely missing from the criteria,
that's a discovery gap — name it in your task report for `delivery-verify`
to raise, don't silently add it yourself.
