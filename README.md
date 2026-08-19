# ai-toolkit

Personal AI toolkit for Claude Code, Codex, and OpenCode: skills, commands,
configs and tools. Clone it on a new machine, run the installer, start
working.

## Requirements

- macOS with [Homebrew](https://brew.sh)
- npm (get it via [nvm](https://github.com/nvm-sh/nvm))

## Install

```bash
git clone https://github.com/irega/ai-toolkit.git
cd ai-toolkit
./scripts/install.sh
```

It also symlinks everything in `skills/` into `~/.claude/skills`,
`~/.codex/skills`, and `~/.config/opencode/skills`, and registers MCP servers
into whichever of Claude Code/Codex/OpenCode are installed.

## What it installs

### Tools

| Tool | Purpose |
|------|---------|
| [RTK](https://www.rtk-ai.app/) | CLI proxy that cuts token usage on dev commands |
| [OpenSpec](https://github.com/Fission-AI/OpenSpec) | Spec-driven planning, run `openspec init` per project to enable |
| [CodeGraph](https://github.com/colbymchenry/codegraph) | Local code knowledge graph MCP server, run `codegraph init` per project to enable |
| [Caveman](https://github.com/JuliusBrussee/caveman) | Ultra-compressed communication mode, cuts token usage ~75% (requires Node) |
| [GitHub CLI](https://cli.github.com/) | `gh` — used by Claude Code for PRs, issues, checks, releases |

### Skills

| Skill | Purpose |
|-------|---------|
| [handoff](skills/handoff/SKILL.md) | Compact the current conversation into a handoff doc for another agent |
| [Humanizer](https://github.com/blader/humanizer) | Rewrite AI-sounding prose to read naturally, installed cross-agent via `npx skills add` |

### MCP servers

Defined once in `configs/mcp-servers.json` (tool-agnostic), registered into
each installed CLI natively (eg: `claude mcp add`).

| Server | Purpose |
|--------|---------|
| [playwright](https://github.com/microsoft/playwright-mcp) | Browser automation (Chrome extension mode) |

Some servers may need env vars (e.g. an extension token). Copy `.env.example` to
`.env.local` and fill it in before running `scripts/mcp/sync-mcp.sh` — values
get injected into the server registration.

## Scripts

`install.sh` runs all of these, but each can also be run standalone:

| Script | Purpose |
|--------|---------|
| `scripts/link-skills.sh` | (Re-)symlink `skills/` into `~/.claude/skills`, `~/.codex/skills`, `~/.config/opencode/skills` |
| `scripts/unlink-skills.sh` | Remove broken skill symlinks from all three skill directories |
| `scripts/mcp/sync-mcp.sh` | Dispatcher: registers MCP servers from `configs/mcp-servers.json` into whichever of claude/codex/opencode are installed |
| `scripts/mcp/sync-mcp-<assistant>.sh` | Register MCP servers with one specific assistant (`claude`, `codex`, or `opencode`) only |
