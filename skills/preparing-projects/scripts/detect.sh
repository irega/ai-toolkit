#!/usr/bin/env bash
# Read-only probe of a repository: spec/plan conventions, optional tools,
# and candidate names for the Engram project. Prints one "key: value" per
# line and never fails on a missing tool or path.
set -u

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 1

has() { [ -e "$1" ] && echo "$1"; }
version() { command -v "$1" >/dev/null 2>&1 && "$1" --version 2>/dev/null | head -1 || echo "not installed"; }

echo "repo_root: $root"

echo "openspec_dir: $(has openspec || echo none)"
echo "openspec_cli: $(version openspec)"

docs="$(for p in docs/adr doc/adr adr docs/decisions docs/specs docs/rfcs \
  docs/superpowers/specs SPEC.md PRD.md .github/ISSUE_TEMPLATE; do has "$p"; done | paste -sd, -)"
echo "spec_docs: ${docs:-none}"

echo "codegraph_cli: $(version codegraph)"
echo "codegraph_index: $([ -d .codegraph ] && echo present || echo missing)"
echo "rtk_cli: $(version rtk)"

# Engram keys memory by project name. Worktrees and clones often have a
# directory name that differs from the repo's real name, so list every
# plausible candidate: remote repo name, main checkout dir, this dir.
remote="" main_checkout=""
if common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
  remote="$(git remote get-url origin 2>/dev/null | sed -E 's#\.git$##; s#.*[/:]##')"
  main_checkout="$(basename "$(dirname "$common")")"
fi
echo "engram_candidates: $(printf '%s\n' "$remote" "$main_checkout" "$(basename "$root")" | awk 'NF && !seen[$0]++' | paste -sd, -)"
