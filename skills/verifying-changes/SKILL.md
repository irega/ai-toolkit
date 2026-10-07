---
name: verifying-changes
description: Verifies that a change meets its spec before it ships, by running the repo's checks, matching each acceptance criterion to evidence, getting E2E evidence for user flows, and detecting drift between spec and code, with a PASS/FAIL verdict and nothing fixed. Use when the user asks to verify, validate, or check that a branch or change meets its spec, plan, or acceptance criteria, for changes of any size, even one line.
---

# Verifying changes

Input: a diff (default: the current branch, working tree included, against
its merge-base with the default branch) and a spec or plan with acceptance
criteria. None given: use the spec or plan in the repo that covers this
change. No acceptance criteria anywhere: stop and ask. Do not invent them.

```
- [ ] 1. Run the repo checks
- [ ] 2. Match each acceptance criterion to evidence
- [ ] 3. Get E2E evidence for user-flow criteria
- [ ] 4. Reconcile spec and code
- [ ] 5. Write the verdict
```

## Rule: report, never fix

This skill reports. It never edits code, and edits the spec only for an
accepted change (step 4). The check and the fix are separate requests,
even when the user asked for both: finish the verdict, then stop.

| Excuse | Reality |
|---|---|
| "It's a one-line fix" | Patched code is unverified code. Report it. |
| "The user said to fix anything I find" | The verdict comes first. The fix is the next request. |
| "Ship it, fix in a follow-up" | Follow-ups are for non-critical notes only. |
| "The spec is close enough to the code" | "Close enough" is the divergence. |

**Red flags:** an edit to a source file; a spec edit with no recorded
acceptance; a criterion marked `met` with no evidence.

## 1. Repo checks

Run the lint, build, and test commands the repo already defines (package
scripts, Makefile, CI config). Each run goes to a log with its exit status:
`cmd > "$TMPDIR/check.log" 2>&1; echo "exit=$?"`. Read back only pass/fail,
failing names, and the decisive error line. None defined: report
`none exist`.

## 2. Acceptance criteria

For each criterion, name the evidence: a test that asserts it, a command
output, or an E2E result. Passing tests that do not assert the criterion
are not evidence. Nothing asserts it, or the evidence shows it fails:
`unmet`. Evidence cannot be obtained, such as a missing tool: `unverified`.

Whether a criterion is met is unclear: dispatch that single judgment to
`delivery-high-reasoning-high` if it exists (see Dispatch below).

## 3. E2E evidence for user flows

For each criterion that describes a user-facing flow:

1. A repo E2E test covers it: run that test inline, logged as in step 1.
   Do not also run Playwright MCP.
2. No E2E covers it: drive the flow with Playwright MCP, even when unit
   tests pass. They do not prove the flow. Snapshots are noisy, so dispatch
   this to `delivery-standard-medium` if it exists (see Dispatch below).
3. Playwright MCP unavailable: `missing evidence`, and the criterion is
   `unverified`. Unavailable means a tool call failed or no Playwright MCP
   tool exists; make the call before saying so. Never claim a pass.

Other criteria never need E2E. Report results, not snapshots.

## 4. Reconcile spec and code

Compare the spec, the diff, the tests, and the E2E evidence:

- **No divergence.**
- **Accepted change:** a human accepted it in this conversation or a
  recorded decision. Update the source spec artifact on the same branch,
  save the decision with the Engram MCP tool `mem_save` if available, then
  repeat steps 1-3.
- **Unaccepted divergence:** a critical failure. Never edit the spec to
  match the code.

An explicit spec line settles the comparison: run it inline and write
`reconciliation: inline` in `Dispatch`. Otherwise, such as behavior the
spec does not mention or a doubtful acceptance, dispatch it to
`delivery-high-reasoning-high` if it exists (see Dispatch below).

## Dispatch

Each dispatch goes to the pinned agent named above if it exists, with
`<agent>--<model>` variants picking one at random. Otherwise use a generic
subagent, which inherits this session's model; the verdict says so. All
other work runs inline. A dispatch costs about 25k tokens of fixed
overhead, so never dispatch for a few commands.

## Verdict

`FAIL`: a failing check, an unmet criterion, or an unaccepted divergence.
`BLOCKED`: no failures, but a criterion is `unverified`. Otherwise `PASS`.

Use exactly this shape. The heading, the labels, and the fixed values stay
in English, verbatim, in any conversation language. Only `<...>` slots are
free text.

```markdown
## Verification: <branch> against <spec path>

- Checks: `<command>` -> pass | fail: <failing names, decisive line>, one per line | none exist
- Criterion <id>: met | unmet | unverified — <evidence or what is missing>
- E2E <id>: repo test `<name>` pass | fail | Playwright MCP pass | fail: <step> | missing evidence: <reason>
- Reconciliation: no divergence | accepted change, spec updated: <path> | unaccepted divergence: <where, what>
- Verdict: PASS | FAIL | BLOCKED
- Failures: <failure>, one per line | none
- Unverified: <criterion>: <what is missing>, one per line | none
- Dispatch: <step>: <agent name> | generic subagent (effort unpinned) | inline, one line per step that dispatches or judges
```
