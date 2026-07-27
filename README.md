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

| Tool | Purpose |
|------|---------|
| [RTK](https://www.rtk-ai.app/) | CLI proxy that cuts token usage on dev commands |

It also symlinks everything in `skills/` into `~/.claude/skills`, and offers to
sync `~/.claude/settings.json` from `configs/claude/settings.json` (this repo's
version is the source of truth; the existing file is backed up first).

`configs/claude/settings.json` enables the [ponytail](https://github.com/DietrichGebert/ponytail)
plugin via `extraKnownMarketplaces`/`enabledPlugins` — Claude Code installs it
automatically on next launch once synced, no extra step needed.
