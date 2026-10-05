#!/usr/bin/env bash
# Read-only probe of a repository's spec/plan convention. Prints one
# "key: value" per line and never fails on a missing tool or path.
set -u

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 1

has() { [ -e "$1" ] && echo "$1"; }

echo "repo_root: $root"
echo "openspec_dir: $(has openspec || echo none)"

docs="$(for p in docs/adr doc/adr adr docs/decisions docs/specs docs/rfcs \
  docs/superpowers/specs SPEC.md PRD.md .github/ISSUE_TEMPLATE; do has "$p"; done | paste -sd, -)"
echo "spec_docs: ${docs:-none}"
