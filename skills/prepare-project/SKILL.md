---
name: prepare-project
description: Use when starting phase 1 of the delivery workflow (before delivery-discovery), to detect a project's spec-driven-development conventions, enable available token-saving/navigation tools, and recover prior session memory.
---

# prepare-project

Phase 1 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract — this skill doesn't restate it).
Run this phase at the `economy` tier — detection and setup here are
mechanical, no judgment call.

## What to do, in order

1. **Detect spec/plan conventions.** Check for `openspec/` (or run
   `openspec --version` to see if the CLI is installed) and any other
   spec/plan artifacts (ADRs, `SPEC.md`, `PRD.md`, issue templates). Record
   what you found — don't initialize a convention that isn't already in use;
   adopting one is a `delivery-discovery` decision, not this phase's.
2. **CodeGraph.** Run `codegraph --version` first. If it succeeds: run
   `codegraph init` when `.codegraph/` is missing, or `codegraph sync` when
   it already exists (keeps the index current without a full rebuild) —
   run it now, in this step, before writing the phase report. Both only
   touch the index, never project files, so they're safe to run
   unprompted. Detecting the CLI and then only *noting* `.codegraph/` is
   missing, without running `init`, is not a valid outcome of this step —
   the only reason to skip `init`/`sync` is `codegraph --version` itself
   failing (CLI not installed). If the CLI isn't available, note it as a
   skipped optional capability.
3. **RTK.** Confirm `rtk --version` works. If it's not installed, note it as
   skipped — commands just run unfiltered, nothing breaks.
4. **Engram.** Call `mem_current_project` then `mem_context` to recover
   prior checkpoints for this project. At the end of this phase, and at
   every later phase transition, save a checkpoint with `mem_save`
   summarizing what changed.

## Degrade explicitly, never silently

For each optional capability (OpenSpec, CodeGraph, RTK, Engram)
that's unavailable, say so in your phase report: what's missing, and what
changes because of it (e.g. "no CodeGraph — later phases fall back to
grep/find"). Never proceed as if a missing tool doesn't matter without
saying why.

## Report

End phase 1 with a short report: conventions detected, tools enabled or
skipped (with reason), and confirmation that prior memory was recovered.
`delivery-discovery` reads this report, not your intermediate tool calls.
For CodeGraph specifically, the report states which command actually ran
(`init` or `sync`) and its result — never just "CodeGraph available" or
"`.codegraph/` missing" with no command run.
