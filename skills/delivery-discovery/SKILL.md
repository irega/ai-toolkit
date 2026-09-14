---
name: delivery-discovery
description: Use when starting phase 2 of the delivery workflow (after prepare-project, before delivery-implement), to turn a request into a spec/plan with acceptance criteria, risks, tests, and dependency-ordered tasks.
---

# delivery-discovery

Phase 2 of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list and tier contract). Run this phase at the
`high_reasoning` tier — a weak plan here compounds into every later phase.

## Step 1: pick where the artifact lives

Detect the project's existing convention, in this order:

1. **OpenSpec already in use** (an `openspec/` dir exists) — the artifact is
   an OpenSpec change: run `openspec explore` if the request is ambiguous or
   open-ended, `openspec propose` if it's already clear what to build.
2. **Another spec/plan convention already in use** (ADRs, `SPEC.md`/`PRD.md`,
   issue templates, a docs/specs dir) — the artifact goes into that
   convention's existing format and location.
3. **Neither exists** — no convention to follow; the artifact is whatever
   `writing-plans` (below) produces.

Never invent a new convention for a project that doesn't already have one.

## Step 2: get to the content

Convention (step 1) is *where the artifact lives*; this is *how you reason
your way to its content* — they're independent, use both together:

- Unclear or open-ended intent → `superpowers:brainstorming` first.
- Once intent is clear → `superpowers:writing-plans` to structure it.

Whatever these produce gets written into the format from step 1 — e.g. an
existing `SPEC.md` convention still gets a `writing-plans`-quality plan, just
committed as an update to `SPEC.md`, not as a new standalone doc.

## Step 3: the output artifact is REQUIRED to have these five parts

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
