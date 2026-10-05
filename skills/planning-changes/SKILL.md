---
name: planning-changes
description: Plans a code change into a file with acceptance criteria, risks, tests, and dependency-ordered tasks, in the project's spec convention (OpenSpec, ADRs, SPEC/PRD docs) or a temp file. Use when the user asks to plan, spec, or design a change before implementing it, says not to touch code yet, or wants acceptance criteria or a task breakdown. Applies to changes of any size, even one flag or one script.
---

# Planning changes

Turn a request into a plan artifact on disk. A plan given only in chat is
not done. This skill never edits project code; it ends at the report.

Copy this checklist and track progress:

```
- [ ] 1. Detect the spec convention
- [ ] 2. Agree the design with the user
- [ ] 3. Write the artifact (all five parts)
- [ ] 4. Write the report
```

## 1. Detect the spec convention

If the conversation already holds a report of this repo's spec conventions,
reuse it. Otherwise run from the repository root:

```bash
bash scripts/detect-convention.sh
```

(`scripts/` is inside this skill's directory.) It prints `openspec_dir` and
`spec_docs`. Pick the first match:

1. `openspec_dir` is not `none`: OpenSpec. If this runtime lacks
   `/opsx:explore` or `/opsx:propose`, run `openspec update`. The artifact
   is `proposal.md`, `specs/<capability>/spec.md`, `design.md`, `tasks.md`.
2. `spec_docs` lists a convention (ADRs, `SPEC.md`/`PRD.md`, issue
   templates, a docs/specs dir): write in that convention's format and
   location.
3. Neither: a single Markdown file outside the repo,
   `${TMPDIR:-/tmp}/plan-<YYYY-MM-DD>-<slug>.md`. Never `git add` it.

Never invent a convention the repo does not already have. Never run
`openspec init`.

## 2. Agree the design with the user

The tools depend on what step 1 picked:

| Step 1 picked | Reach the design with | Write the artifact with |
|---|---|---|
| OpenSpec | `/opsx:explore` | `/opsx:propose` |
| Any other convention, or none | **REQUIRED SUB-SKILL:** superpowers:brainstorming | **REQUIRED SUB-SKILL:** superpowers:writing-plans for the tasks |

With OpenSpec, do not invoke brainstorming or writing-plans. OpenSpec's own
commands read the project's specs and `config.yaml` rules.

Outside OpenSpec, brainstorming's Spike and Bounded paths end in chat, but
this skill still writes the file in step 3. Save brainstorming's spec and
writing-plans' output into the step 3 artifact, not their default
locations. Never write `docs/superpowers/` unless step 1 picked it.

Write no artifact file until the user approves the design in chat. With
OpenSpec, settle open questions in `/opsx:explore` before `/opsx:propose`.

A required sub-skill not installed: ask the clarifying questions yourself,
one at a time, propose 2–3 approaches with a recommendation, and get
approval. List only missing sub-skills under `Degraded`.

## 3. Write the artifact

The artifact must cover five parts. Map each part onto the convention:

| Part | OpenSpec | Other convention / temp file |
|---|---|---|
| Source spec/plan | `proposal.md` + `design.md` | "Source spec/plan" section |
| Acceptance criteria | `spec.md` Scenarios (WHEN/THEN) | "Acceptance criteria" section |
| Risks | `design.md` "Risks / Trade-offs" | "Risks" section |
| Tests | add a `## Tests` section to `design.md`, one test per scenario | "Tests" section, matched to acceptance criteria |
| Tasks with dependencies | `tasks.md`, each task ending in `(independent)` or `(depends on 1.2)` | "Tasks" section, each task marked independent or naming what it depends on |

A part with nothing in it still appears, written as `none identified`.

## 4. Write the report

The report is this skill's output. Use exactly this shape. The heading,
the labels, and the fixed values stay in English, verbatim, in any
conversation language. Only `<...>` slots are free text.

```markdown
## Change planned: <short title>

- Artifact: <path>, one per line
- Convention: OpenSpec | <convention> at <location> | none (temp file, not committed)
- Source spec/plan: present | none identified
- Acceptance criteria: <count> | none identified
- Risks: <count> | none identified
- Tests: <count> | none identified
- Tasks: <count>, <count> with dependencies | none identified
- Degraded: <capability>: <what changes because of it>, one per line | none
```

Stop after the report. Implementation is a separate request.
