---
name: delivery-pr
description: Use when starting the final phase of the delivery workflow, right after delivery-verify's gates passed, to size and open the pull request.
---

# delivery-pr

Final phase of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list). Only runs after `delivery-verify`'s gates passed.
Run this phase at the `economy` tier — the heavy decisions (what's
independent, whether it's ready) already happened in `delivery-discovery`
and `delivery-verify`; this phase packages that into PRs, it doesn't
re-judge it.

## Rule 1: one PR per independent concern, always draft

Split the diff into separate PRs along the same independence lines
`delivery-discovery`'s tasks used — an unrelated bundle of small changes
(e.g. a README tweak plus an unrelated script) is not one PR just because
it landed in one commit or one branch. Recommend a feature/integration
branch, with each small PR targeting it instead of the repo's main branch,
only when several small PRs are needed for one larger effort.

Once a PR's diff is ready, open it as a **draft PR** — never ready-for-review
— regardless of how small it is or how confident the gates make you feel.
`gh pr create --draft ...`.

**No exceptions:**
- "It's tiny, already reviewed by delivery-verify" doesn't skip `--draft`.
- "In a hurry, just get it opened" doesn't bundle unrelated changes into
  one PR, and doesn't drop `--draft`.

| Excuse | Reality |
|---|---|
| "It already passed every gate, why keep it draft" | Draft signals "not yet asked for human review", independent of whether it passed checks — those are different questions. |
| "Splitting this is slower" | The human asked for small PRs specifically so review stays easy; bundling defeats the reason this phase exists. |

## Rule 2: PR title, body, and any touched docs are in English

Regardless of the conversation's language.

## Rule 3: follow the repo's own PR template if it has one

Check for `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`,
`docs/PULL_REQUEST_TEMPLATE.md`, or `PULL_REQUEST_TEMPLATE.md` at the repo
root. If one exists, fill in its sections — don't replace it with a
freeform body. `gh pr create --body` bypasses the template, so read it and
reproduce its structure yourself. No template found → write a normal
Summary/Test plan body.

## Rule 4: use `show-me` for structure and flow, not just visuals

`show-me` isn't only diagrams — pseudocode, call trees, file trees, and
diffs are all in scope, and these read faster in a PR body than the
equivalent paragraph. Use it whenever a call tree, file tree, small
diagram, or before/after diff would make the change's structure or flow
clearer than prose — which is most PRs that touch more than one file, not
just UI/branching-state changes.

## Rule 5: `gh` must be usable, or degrade explicitly

Before opening the PR, confirm `gh auth status` succeeds and the repo's
remote is on GitHub. If `gh` isn't installed/authenticated, or the remote
is a non-GitHub host (Azure DevOps, GitLab, Bitbucket, ...) with no CLI
this runtime can drive: don't silently skip opening the PR. Instead, write
the title and body (per Rules 1-4) to a `.md` file and tell the human where
it is, so they can paste it into whatever host they use. Never invent a
host-specific CLI call this runtime doesn't actually have.
