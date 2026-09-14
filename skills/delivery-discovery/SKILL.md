---
name: delivery-discovery
description: Use when starting phase 2 of the delivery workflow (after prepare-project, before delivery-implement), to turn a request into a spec/plan with acceptance criteria, risks, tests, and dependency-ordered tasks.
---

# delivery-discovery

Phase 2 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract). Run this phase at the
`high_reasoning` tier — a weak plan here compounds into every later phase.

## Step 1: pick a planning convention

In this order, use the first that applies:

1. **OpenSpec already in use** (an `openspec/` dir exists) — run `openspec
   explore` if the request is ambiguous or open-ended, `openspec propose` if
   it's already clear what to build.
2. **Another spec/plan convention already in use** in this repo (ADRs,
   `SPEC.md`/`PRD.md`, issue templates, a docs/specs dir) — follow that
   convention instead of introducing a new one.
3. **Neither exists** — fall back to `superpowers:brainstorming` (unclear
   intent) or `superpowers:writing-plans` (clear intent, needs a plan).

Never invent a fourth convention. Adopting OpenSpec or any other convention
for a project that doesn't already use one is out of scope for this phase.

## Step 2: the output artifact is REQUIRED to have these five parts

Whatever convention produced it, the artifact this phase hands to
`delivery-implement` must contain all five, explicitly labeled — a technical
approach with no acceptance criteria or risks isn't a finished discovery
artifact, it's a design note:

1. **Source spec/plan** — the approach itself.
2. **Acceptance criteria** — the observable conditions that make this done.
3. **Risks** — what could go wrong or what's uncertain about the approach.
4. **Tests** — what will be tested and how (unit/integration/E2E), matched
   to the acceptance criteria.
5. **Tasks with dependencies** — the work broken into deliverables, marked
   with which tasks are independent (safe to parallelize in
   `delivery-implement`) and which depend on another task finishing first.

If a section is genuinely empty (e.g. no risks worth naming), say so
explicitly — `Risks: none identified` — instead of omitting the heading.
