# ai-toolkit

Personal AI toolkit for Claude Code: skills, commands, configs and tools.
Clone it on a new machine, run the installer, start working.

## Requirements

- macOS with [Homebrew](https://brew.sh)

## Install

```bash
git clone https://github.com/irega/ai-toolkit.git
cd ai-toolkit
./scripts/install.sh
```

## What it installs

### Tools

| Tool | Purpose |
|------|---------|
| [RTK](https://www.rtk-ai.app/) | CLI proxy that cuts token usage on dev commands |

It also symlinks everything in `skills/` into `~/.claude/skills`, and offers to
sync `~/.claude/settings.json` from `configs/claude/settings.json` (this repo's
version is the source of truth; the existing file is backed up first).

### Skills

| Skill | Purpose |
|-------|---------|
| [caveman](skills/caveman/SKILL.md) | Ultra-compressed communication mode, cuts token usage ~75% |

### Plugins

Enabled via `extraKnownMarketplaces`/`enabledPlugins` in `configs/claude/settings.json` —
Claude Code installs them automatically on next launch once settings.json is synced.

| Plugin | Purpose |
|--------|---------|
| [ponytail](https://github.com/DietrichGebert/ponytail) | Forces minimal, YAGNI-driven solutions (stdlib/native before dependencies) |

## Scripts

`install.sh` runs all of these, but each can also be run standalone:

| Script | Purpose |
|--------|---------|
| `scripts/sync-config.sh` | Re-sync `~/.claude/settings.json` from this repo (with backup) |
| `scripts/clean-config-backups.sh [keep_count]` | Delete old `settings.json.backup.*` files (`DRY_RUN=1` to preview) |
| `scripts/link-skills.sh` | (Re-)symlink `skills/` into `~/.claude/skills` |
