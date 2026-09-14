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

1. **OpenSpec already in use** (an `openspec/` dir exists) — use its
   installed workflow for this runtime: `/opsx:explore` (ambiguous,
   open-ended request) or `/opsx:propose` (already clear what to build).
   These are per-runtime slash-commands/skills OpenSpec generates, not raw
   `openspec` CLI subcommands. If this runtime's `opsx:*` commands aren't
   installed yet, run `openspec update` to add them before proceeding. The
   artifact is OpenSpec's own set: `proposal.md`, `specs/<capability>/spec.md`
   (delta), `design.md`, `tasks.md`.
2. **Another spec/plan convention already in use** (ADRs, `SPEC.md`/`PRD.md`,
   issue templates, a docs/specs dir) — the artifact goes into that
   convention's existing format and location.
3. **Neither exists** — use `superpowers:brainstorming` (see Step 2); the
   artifact is whatever it and `writing-plans` produce.

Never invent a new convention for a project that doesn't already have one.

## Step 2: get to the content

Convention (step 1) is *where the artifact lives*; this is *how you reason
your way to its content* — independent of each other, use both together.

For the "neither" case: `superpowers:brainstorming` classifies the request
as Spike, Bounded, or Architectural, and only its Architectural path writes
a spec file by default — Spike and Bounded end in a chat-only
recommendation/design with no persisted file. **Override that default for
this workflow**: whichever path brainstorming takes, after the human
approves the design in chat, persist the Step 3 parts to a file (e.g.
`docs/superpowers/specs/YYYY-MM-DD-<topic>.md`) before handing off to
`delivery-implement` — it reads an artifact, not a chat transcript. Use
`superpowers:writing-plans` for the task/dependency breakdown regardless of
which brainstorming path was taken.

## Step 3: the artifact is REQUIRED to cover these five parts

A technical approach with no acceptance criteria or risks isn't a finished
discovery artifact, it's a design note. Map each part onto the convention
from Step 1 instead of forcing a mismatched heading set:

| Part | OpenSpec | Any other convention / brainstorming+writing-plans |
|---|---|---|
| Source spec/plan | `proposal.md` + `design.md` | Explicit "Source spec/plan" section |
| Acceptance criteria | `spec.md` Scenarios (WHEN/THEN) | Explicit "Acceptance criteria" section |
| Risks | `design.md`'s own "Risks / Trade-offs" | Explicit "Risks" section |
| Tests | Not a native OpenSpec artifact — add a `## Tests` section to `design.md` | Explicit "Tests" section, matched to acceptance criteria |
| Tasks with dependencies | `tasks.md` — annotate dependencies inline (e.g. `(depends on 1.2)`); the template has no native dependency field | Explicit "Tasks" section, each task marked independent or naming what it depends on |

If a part is genuinely empty (e.g. no risks worth naming), say so explicitly
— `Risks: none identified` — instead of omitting it.
