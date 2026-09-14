---
name: delivery-pr
description: Use when starting the final phase of the delivery workflow, right after delivery-verify's gates passed, to size and open the pull request.
---

# delivery-pr

Final phase of the delivery workflow (see `../delivery-workflow/references/contract.md`
for the full phase list). Only runs after `delivery-verify`'s gates passed.

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

## Rule 3: `show-me` only when a visual materially helps

Most PRs need none. Use it only when a diagram or screenshot would clear up
something prose can't (e.g. a UI change, a flow with branching states).

## Rule 4: `gh` must be usable, or say so explicitly

Before opening the PR, confirm `gh auth status` succeeds. If `gh` isn't
installed or isn't authenticated, don't silently skip opening the PR — stop
and report exactly what's missing (matching `prepare-project`'s pattern for
optional capabilities), so a human can fix it and this phase can be retried.
