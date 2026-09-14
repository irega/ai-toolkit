---
name: prepare-project
description: Use when starting phase 1 of the delivery workflow (before delivery-discovery), to detect a project's spec-driven-development conventions, enable available token-saving/navigation tools, and recover prior session memory.
---

# prepare-project

Phase 1 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract — this skill doesn't restate it).

## What to do, in order

1. **Detect spec/plan conventions.** Check for `openspec/` (or run
   `openspec --version` to see if the CLI is installed) and any other
   spec/plan artifacts (ADRs, `SPEC.md`, `PRD.md`, issue templates). Record
   what you found — don't initialize a convention that isn't already in use;
   adopting one is a `delivery-discovery` decision, not this phase's.
2. **CodeGraph.** If `.codegraph/` is missing and the `codegraph` CLI is
   available, run `codegraph init` — it only builds the index, it doesn't
   touch project files, so it's safe to run unprompted. If `.codegraph/`
   already exists, leave it alone; don't re-init. If the CLI isn't
   available, note it as a skipped optional capability.
3. **Caveman.** If the `caveman:caveman-init` skill is available and this
   repo hasn't had the activation rule dropped in yet, run it. If no Caveman
   tooling is available at all, note it as skipped.
4. **RTK.** Confirm `rtk --version` works. If it's not installed, note it as
   skipped — commands just run unfiltered, nothing breaks.
5. **Engram.** Call `mem_current_project` then `mem_context` to recover
   prior checkpoints for this project. At the end of this phase, and at
   every later phase transition, save a checkpoint with `mem_save`
   summarizing what changed.

## Degrade explicitly, never silently

For each optional capability (OpenSpec, CodeGraph, Caveman, RTK, Engram)
that's unavailable, say so in your phase report: what's missing, and what
changes because of it (e.g. "no CodeGraph — later phases fall back to
grep/find"). Never proceed as if a missing tool doesn't matter without
saying why.

## Report

End phase 1 with a short report: conventions detected, tools enabled or
skipped (with reason), and confirmation that prior memory was recovered.
`delivery-discovery` reads this report, not your intermediate tool calls.
