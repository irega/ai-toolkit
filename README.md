# ai-toolkit

Personal AI toolkit for Claude Code: skills, commands, configs and tools.
Clone it on a new machine, run the installer, start working.

## Requirements

- macOS with [Homebrew](https://brew.sh)
- npm (get it via [nvm](https://github.com/nvm-sh/nvm))

## Install

```bash
git clone https://github.com/irega/ai-toolkit.git
cd ai-toolkit
./scripts/install.sh
```

It also symlinks everything in `skills/` into `~/.claude/skills`, and offers to
sync `~/.claude/settings.json` from `configs/claude/settings.json` (this repo's
version is the source of truth; the existing file is backed up first).

## What it installs

### Tools

| Tool | Purpose |
|------|---------|
| [RTK](https://www.rtk-ai.app/) | CLI proxy that cuts token usage on dev commands |
| [OpenSpec](https://github.com/Fission-AI/OpenSpec) | Spec-driven planning, run `openspec init` per project to enable |
| [CodeGraph](https://github.com/colbymchenry/codegraph) | Local code knowledge graph MCP server, run `codegraph init` per project to enable |
| [Caveman](https://github.com/JuliusBrussee/caveman) | Ultra-compressed communication mode, cuts token usage ~75% (requires Node) |
| [Headroom](https://github.com/chopratejas/headroom) | Compresses Claude Code's own API traffic via a local proxy (complements RTK, which rewrites shell commands); installed via `uv tool install`, wired in by `headroom init -g claude` (hooks + `ANTHROPIC_BASE_URL` in `settings.json`) |

### Skills

| Skill | Purpose |
|-------|---------|
| [handoff](skills/handoff/SKILL.md) | Compact the current conversation into a handoff doc for another agent |

### Plugins

Enabled via `extraKnownMarketplaces`/`enabledPlugins` in `configs/claude/settings.json` —
Claude Code installs them automatically on next launch once settings.json is synced.

| Plugin | Purpose |
|--------|---------|
| [ponytail](https://github.com/DietrichGebert/ponytail) | Forces minimal, YAGNI-driven solutions (stdlib/native before dependencies) |
| [humanizer](https://github.com/blader/humanizer) | Rewrites responses to sound more natural, less AI-generated |
| [superpowers](https://github.com/obra/superpowers) | Skills library: TDD, debugging, planning, code review, writing skills (replaces this repo's old `write-a-skill`) |

### MCP servers

Registered with `claude mcp add --scope user` from `configs/claude/mcp.json`.

| Server | Purpose |
|--------|---------|
| [playwright](https://github.com/microsoft/playwright-mcp) | Browser automation (Chrome extension mode) |

Some servers may need env vars (e.g. an extension token). Copy `.env.example` to
`.env.local` and fill it in before running `sync-mcp.sh` — values get injected
into the server registration.

## Scripts

`install.sh` runs all of these, but each can also be run standalone:

| Script | Purpose |
|--------|---------|
| `scripts/sync-config.sh` | Re-sync `~/.claude/settings.json` from this repo (with backup) |
| `scripts/clean-config-backups.sh [keep_count]` | Delete old `settings.json.backup.*` files (`DRY_RUN=1` to preview) |
| `scripts/link-skills.sh` | (Re-)symlink `skills/` into `~/.claude/skills` |
| `scripts/unlink-skills.sh` | Remove broken skill symlinks from `~/.claude/skills` |
| `scripts/sync-mcp.sh` | Re-register MCP servers from `configs/claude/mcp.json` |
