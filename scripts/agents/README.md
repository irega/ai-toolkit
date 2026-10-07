# Pinned agents

A tier in `skills/delivering-changes/tiers.json` fixes the model. Reasoning
effort is a second dial, and no runtime lets a skill set it on an ad-hoc
dispatch:

| Runtime | Dispatch call accepts | Effort pinnable via |
|---------|----------------------|---------------------|
| Claude Code | `subagent_type`, `model`, `prompt`, no effort argument | `effort:` in `~/.claude/agents/<name>.md` frontmatter |
| Codex | agent name, no effort argument | `model_reasoning_effort` in `~/.codex/agents/<name>.toml` |
| OpenCode | `task` tool, no per-call model override either | `model:` and `variant:` in `~/.config/opencode/agents/<name>.md` |

An unpinned subagent inherits the session's model and effort. So
`tiers.json` declares per tier both the candidates and the `efforts`, and
these scripts generate one pinned agent per (tier, effort, candidate).

## Naming

`delivery-<tier>-<effort>`, underscores in the tier become dashes:
`delivery-high-reasoning-high`, `delivery-standard-medium`,
`delivery-standard-low`, `delivery-economy-low`.

OpenCode's `task` tool always inherits the calling agent's model, so one
file cannot offer a choice at dispatch time. When a tier lists more than
one OpenCode candidate, the generator writes one file per candidate,
suffixed `--<model>` (for example `delivery-standard-low--minimax-m3`). The
caller picks one of those files at random. A tier with one candidate keeps
the plain name. Claude and Codex have one candidate per tier, so their
names are never suffixed.

## Scripts

- `sync-agents.sh`: generates agents for every installed CLI. The
  `sync-agents-<runtime>.sh` scripts do one runtime each. Agent files are
  rendered from `templates/` and are never hand-edited.
- `prune-agents.sh`: removes every `delivery-*` file, in all three agent
  directories, that current `tiers.json` would not generate. It ignores
  which CLIs are installed, since a leftover can outlive an uninstall.

After editing `tiers.json`, run `sync-agents.sh`, then `prune-agents.sh`.

## OpenCode effort

OpenCode `variant` values are defined by each model. The generator writes
`variant:` only for a candidate with a `variants` map in `tiers.json`.
Without one it pins only the model and prints a warning that names every
agent whose effort is unpinned. That tier's effort split is then advisory
under OpenCode.
