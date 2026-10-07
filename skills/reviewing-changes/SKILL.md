---
name: reviewing-changes
description: Reviews a branch, diff, or PR adversarially from fresh context, with a separate verdict per lens (correctness, security, simplicity, design, conventions), critical findings flagged, and nothing fixed. Use when the user wants an independent, adversarial, or second-opinion review of their changes before opening or merging a PR, for diffs of any size.
---

# Reviewing changes

Input: a base ref, a PR number, or nothing (the current branch, working
tree included, against its merge-base with the default branch). Optional:
acceptance criteria or a spec to review against. None given: use a spec or
plan in the repo that covers this change, if one exists.

Invoking this skill authorizes dispatching review subagents, never editing
files.

```
- [ ] 1. Resolve the diff and measure it
- [ ] 2. Pick the passes
- [ ] 3. Dispatch each pass to a fresh context
- [ ] 4. Re-dispatch ambiguous findings
- [ ] 5. Write the verdict
```

## Step 1: resolve the diff

- PR number: `gh pr diff <n>`.
- Otherwise:
  `base=$(git merge-base HEAD origin/main || git merge-base HEAD main)`,
  then `git diff --stat "$base"` for the size.

The diff **touches a trust boundary** when it handles data from another
user or the network: requests, authentication, authorization, secrets,
uploaded or downloaded files, deserialization, or shell, SQL, or paths
built from that data. Arguments of a local CLI run by its own user are
not a trust boundary.

## Step 2: pick the passes

| Lens | Pinned agent | Looks for |
|---|---|---|
| Correctness | `delivery-standard-medium` | wrong logic, off-by-one, broken callers, unmet criteria |
| Security | `delivery-standard-medium` | the current OWASP Top 10: broken access control, injection, authentication and cryptographic failures, insecure design, misconfiguration, integrity failures (only when a trust boundary is touched) |
| Simplicity | `delivery-standard-low` | code no criterion or caller needs: unused flags, parameters, abstractions |
| Design | `delivery-standard-low` | coupling, duplication, wrong layer, unclear names |
| Conventions | `delivery-standard-low` | departures from the repo's written rules and surrounding style |

**Use a dedicated skill when installed.** The Simplicity lens invokes
`ponytail-review`; the Security pass invokes `security-review`. Check
which are installed before dispatching; a pass prompt names only those,
as "Invoke `<skill>` first", never "if installed". Missing skill: the
pass uses the "Looks for" column. Either way the pass returns
the shape in Step 3, not the skill's own.

**Under about 150 changed lines and no trust boundary:** one combined pass
to `delivery-standard-medium` covering the four other lenses, with a
verdict per lens. Otherwise one pass per row.

## Step 3: dispatch to a fresh context

- The pinned agent exists (check `~/.claude/agents/`, or the runtime's
  agent list; with `--<model>` variants, pick one at random): dispatch to
  it by name.
- It does not exist: use a generic subagent and record
  `generic subagent (effort unpinned)`.
- No subagent support: stop and give the user a prompt to run in a new
  session.

Never review in this context: it has already seen the code. Run passes in
parallel when the runtime allows it.

Each pass prompt carries: how to get the diff, its lenses with their
"Looks for" or the skill to invoke, the acceptance criteria if any, the
definition of critical below, "report only, do not edit any file",
"report only findings of your lenses", and the return shape per lens:
`PASS`, or one line per finding with `path:line`, severity, problem, and a
one-line fix. The pass ends with `Skills: <invoked skills> | none`, which
fills the `Dispatch` line.

**Critical** means shipping it would cause a regression, a security hole,
or an unmet acceptance criterion. Everything else is `non-critical`,
including a weak or missing test: the bug it misses is the critical
finding.

## Step 4: ambiguous findings

A pass unsure of a finding, or two passes contradicting each other:
re-dispatch only that pass to `delivery-high-reasoning-high` (or a generic
subagent) and keep its answer.

## Rule: report, never fix

Copy findings as the passes returned them: none dropped, softened, or
added. The same problem reported by several passes stays once, under the
lens whose "Looks for" covers it. Different problems on one line stay
apart. Edit no code, even for a one-line fix.

| Excuse | Reality |
|---|---|
| "It's a one-line fix" | Fixed code is unreviewed code. Report it. |
| "I already read the diff, I can review it here" | That context is anchored. Fresh context is the point. |
| "The user wants it ready for the PR" | They asked for a review. The fix is a new request. |

**Red flags:** an edit tool call during this skill; a lens verdict written
without a dispatched pass; a finding missing from the passes' output.

## Verdict

Use exactly this shape. The heading, the labels, and the fixed values stay
in English, verbatim, in any conversation language. Only `<...>` slots are
free text. `Verdict` is `FAIL` when any finding is critical.

```markdown
## Review: <branch or PR> against <base>

- Diff: <n> changed lines, <n> files
- Criteria: <source> | none

### Correctness: PASS | FINDINGS
- `<path>:<line>` critical | non-critical: <problem>. Fix: <one line>

### Security: PASS | FINDINGS | SKIPPED (no trust boundary)
### Simplicity: PASS | FINDINGS
### Design: PASS | FINDINGS
### Conventions: PASS | FINDINGS

- Verdict: PASS | FAIL
- Dispatch: <combined | lens>: <agent name> | generic subagent (effort unpinned); skill: <name> | none, one line per pass
```
