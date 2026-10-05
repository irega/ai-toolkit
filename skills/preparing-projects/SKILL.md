---
name: preparing-projects
description: Detects a repository's spec/plan conventions (OpenSpec, ADRs, SPEC/PRD docs), indexes it with CodeGraph, checks RTK, and recovers prior Engram memory. Use when starting work in a repository or a new session, or when the user asks to prepare, set up, or get a project ready before planning or changing anything.
---

# Preparing projects

Get a repository ready for agent work and report what is available. This
skill only detects and indexes. It never adopts a new convention or edits
project files.

Copy this checklist and track progress:

```
- [ ] 1. Probe the repo
- [ ] 2. Index with CodeGraph
- [ ] 3. Recover Engram memory
- [ ] 4. Write the report
```

## 1. Probe the repo

Run from the repository root:

```bash
bash scripts/detect.sh
```

(`scripts/` is inside this skill's directory.) It prints `key: value` lines:
`openspec_dir`, `openspec_cli`, `spec_docs`, `codegraph_cli`,
`codegraph_index`, `rtk_cli`, `engram_candidates`. Use this output instead
of probing by hand. Shell globs like `ls adr*` fail under zsh when nothing
matches.

A convention counts only if its files exist in the repo. An installed
`openspec` CLI with no `openspec/` directory means the repo does not use
OpenSpec. Do not run `openspec init`.

## 2. Index with CodeGraph

Invoking this skill authorizes indexing. Both commands write only to
`.codegraph/`.

| `codegraph_cli` | `codegraph_index` | Run |
|---|---|---|
| a version | `missing` | `codegraph init` |
| a version | `present` | `codegraph sync` |
| `not installed` | any | nothing, report as skipped |

Run the command now. Noting that `.codegraph/` is missing is not enough.
"No files found to index" is a valid result: report it. If `git status`
then shows `.codegraph/` as untracked, say so in the report. Do not edit
`.gitignore`.

## 3. Recover Engram memory

1. Call the Engram MCP tool `mem_current_project`, then `mem_context` with
   that project.
2. If `mem_context` returns no observations, retry with each name in
   `engram_candidates`, in order. A worktree or clone usually has a
   directory name that differs from the project's memory key. Stop at the
   first name that returns observations, and use it for any later save.
3. Engram MCP tools unavailable: report as skipped.

Save a checkpoint with `mem_save` only when this run learned something the
recovered memory does not already hold. Examples: an index created for the
first time, a convention not recorded before. Title it
`Project prepared: <repo>`. Otherwise save nothing.

## 4. Write the report

The report is this skill's output. Callers read it, not the tool calls.
Use exactly this shape. The heading, the labels, and the fixed values
(ran `init`, none, skipped (...)) stay in English, verbatim, in any
conversation language. Only `<...>` slots are free text.

```markdown
## Project prepared: <repo>

- Spec conventions: <what exists and where> | none found
- CodeGraph: ran `init` | ran `sync` | skipped (CLI not installed) — <result line>
- RTK: <version> | skipped (not installed)
- Engram: project `<name used>` — <one-line gist of recovered context> | no prior memory | skipped (MCP unavailable)
- Degraded: <capability>: <what changes because of it>, one per line | none
```

Every unavailable capability goes in `Degraded` with its consequence.
Examples: "CodeGraph: code search falls back to grep/find". "RTK: command
output runs unfiltered".
