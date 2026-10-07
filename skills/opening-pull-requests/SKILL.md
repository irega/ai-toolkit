---
name: opening-pull-requests
description: Splits the current work into one draft pull request per independent concern and opens each, following the repo's PR template, in English, with a fallback file when no tool reaches the remote host. Use when the user wants to open, create, or raise a PR (or several small PRs) for the current branch or changes, even when the change is tiny or the user is in a hurry.
---

# Opening pull requests

Invoking this skill authorizes pushing the branch and opening **draft** PRs.
Do not ask again.

```
- [ ] 1. Split the diff by independent concern
- [ ] 2. Read the PR template and the title convention
- [ ] 3. Pick the tool for the remote's host
- [ ] 4. Open each PR as a draft, or write its fallback file
- [ ] 5. Write the result
```

## Rule 1: one PR per independent concern, always draft

Split by independent concern. Use the plan's task list when one is
available, for example a plan with tasks and dependencies. Otherwise judge
from the diff. Unrelated changes (a README tweak and an unrelated script)
get separate PRs, even when they share one commit or branch. Recommend an
integration branch, with each small PR targeting it, only when several small
PRs serve one larger effort.

Open every PR as a **draft**, whatever its size or how sure you are:
`gh pr create --draft ...`.

**No exceptions:**
- "It's tiny" or "already reviewed" does not drop `--draft`.
- "In a hurry" does not bundle unrelated changes, and does not drop `--draft`.

| Excuse | Reality |
|---|---|
| "It passed every check, why keep it draft" | Draft means "not yet asked for human review". Passing checks is a different question. |
| "Splitting is slower" | Small PRs keep review easy. Bundling defeats that. |

## Rule 2: title, body, and touched docs are in English

In any conversation language.

## Rule 3: follow the repo's PR template

Look for `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`,
`docs/PULL_REQUEST_TEMPLATE.md`, or `PULL_REQUEST_TEMPLATE.md` at the root.
Found: fill in its sections. `gh pr create --body` bypasses the template, so
reproduce its structure yourself. None: write a Summary and Test plan body.

## Rule 4: show structure when it helps

For a change touching more than one file, add a file tree, call tree, small
diagram, or before/after diff when it reads faster than prose. `show-me`
installed: invoke it. Not installed: use a markdown tree or diff block in
the body, and list `show-me` under `Degraded`.

## Rule 5: use a tool that reaches the remote's host, or write a fallback file

Pick the tool by the remote's host:
- GitHub: `gh`, after `gh auth status` succeeds.
- Azure DevOps: the Azure DevOps MCP tool `repo_pull_request_write`
  (`action: create`, `isDraft: true`), when a configured server's
  organization matches the remote's. Each server serves one organization,
  so match on it. Create the PR only after the branch is on the remote. A
  failed push is a blocker, not a reason to open it from a local branch.
- Any other host, or no matching tool (no `gh`, not authenticated, no
  server for that organization): do not skip the PR. Write one `.md` file
  per PR: `# <title>` on the first line, a blank line, then the body. A
  title given only in chat is a dropped title.

Never invent a CLI or tool call this runtime does not have. Say which one
opened each PR, or that none did, in the result.

Match the title format to the repo: read `git log` and merged PRs. Use
Conventional Commits when the history shows no convention.

## Result

Use exactly this shape. Labels and fixed values stay in English, verbatim,
in any conversation language. Only `<...>` slots are free text. One line per
PR.

```markdown
## Pull requests: <branch>

- <title> | <URL or fallback .md path> | base: <branch> | draft: yes

- Split out: <concern>: <why independent>, one per line | none
- Via: gh | Azure DevOps MCP | fallback file
- Degraded: <skill or tool>: <what changes because of it>, one per line | none
```
