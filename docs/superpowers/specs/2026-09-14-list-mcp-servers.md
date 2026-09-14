# list-mcp-servers.sh

## Source spec/plan

Add `scripts/mcp/list-mcp-servers.sh`, a read-only script that prints the
servers defined in `configs/mcp-servers.json` as a table (name, type,
command/url). Classified as a Spike/Bounded task (single file, no design
ambiguity, matches the existing `scripts/mcp/*.sh` conventions: `#!/usr/bin/env
bash`, `set -euo pipefail`, repo-root resolution via `dirname "$0"`, `jq`
required and checked up front).

## Acceptance criteria

1. Running `scripts/mcp/list-mcp-servers.sh` from any working directory
   prints one row per server in `configs/mcp-servers.json`, with at least
   `name` and `type` columns, plus `command` (joined with args) for local
   servers or `url` for remote servers.
2. If `jq` is missing, the script exits non-zero with a clear error (matches
   existing sibling scripts' behavior).
3. If `configs/mcp-servers.json` is missing, the script exits non-zero with a
   clear error.
4. Output is a table (aligned columns), not raw JSON.

## Risks

None identified — read-only script, no side effects, no secrets touched
(unlike the sync-mcp-*.sh scripts, this never reads `.env.local`/env keys).

## Tests

Manual invocation (matches this repo's existing convention — no test runner
in this repo):
- `scripts/mcp/list-mcp-servers.sh` against the current
  `configs/mcp-servers.json` (one `playwright` server) → prints a table row
  for `playwright`.
- Temporarily rename `configs/mcp-servers.json` and run the script → exits
  non-zero with an error message.
- Run with `jq` temporarily shadowed off `PATH` → exits non-zero with a clear
  "jq required" error.

## Tasks

1. Write `scripts/mcp/list-mcp-servers.sh` (independent, no dependencies).
