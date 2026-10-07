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
| [Engram](https://github.com/Gentleman-Programming/engram) | Persistent memory MCP server (SQLite + FTS5), agent-agnostic |
| [CodeBurn](https://github.com/getagentseal/codeburn) | Local AI coding token and cost tracking across tools and agents |

### Skills

| Skill | Purpose |
|-------|---------|
| [handoff](skills/handoff/SKILL.md) | Compact the current conversation into a handoff doc for another agent |
| [delivery-workflow](skills/delivery-workflow/SKILL.md) | Entrypoint: orchestrates the phases below for a request, end to end |
| [preparing-projects](skills/preparing-projects/SKILL.md) | Phase 1: detect spec conventions, index with CodeGraph, check RTK, recover Engram memory |
| [planning-changes](skills/planning-changes/SKILL.md) | Plan a change: spec/plan with acceptance criteria, risks, tests, tasks |
| [implementing-tasks](skills/implementing-tasks/SKILL.md) | Implement a plan: test-first per task, RED/GREEN report |
| [delivery-verify](skills/delivery-verify/SKILL.md) | Phase 4: conformance checks, fresh-context reviews, E2E evidence, spec reconciliation |
| [delivery-pr](skills/delivery-pr/SKILL.md) | Phase 5: size and open the draft PR(s) |
| [Humanizer](https://github.com/blader/humanizer) | Rewrite AI-sounding prose to read naturally, installed cross-agent via `npx skills add` |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | Forces minimal, lazy-first code solutions, installed cross-agent via `npx skills add` |
| [Superpowers](https://github.com/obra/superpowers) | Process skills (brainstorming, TDD, systematic debugging, plan writing, code review...), installed cross-agent via `npx skills add` |
| [show-me](https://github.com/humanlayer/skills) | Explains the current topic with concise diagrams, code-shape sketches, and focused HTML artifacts, installed cross-agent via `npx skills add` |

### MCP servers

Defined once in `configs/mcp-servers.json` (tool-agnostic), registered into
each installed CLI natively (eg: `claude mcp add`).

| Server | Purpose |
|--------|---------|
| [playwright](https://github.com/microsoft/playwright-mcp) | Browser automation (Chrome extension mode) |
| [Azure DevOps](https://github.com/microsoft/azure-devops-mcp) | Backlog, work items and pull requests (optional, one instance per configured organization) |

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
| `scripts/agents/sync-agents.sh` | Dispatcher: generates one pinned subagent per (tier, effort) pair in `skills/delivery-workflow/tiers.json` for whichever of claude/codex/opencode are installed — no runtime accepts a model or effort argument on an ad-hoc dispatch, so a predefined agent is the only channel |
| `scripts/agents/sync-agents-<assistant>.sh` | Generate pinned subagents for one specific assistant (`claude`, `codex`, or `opencode`) only, rendered from `scripts/agents/templates/` |
| `scripts/agents/prune-agents.sh` | Remove `delivery-*` pinned agents that current `tiers.json` would not generate — leftovers from a renamed/removed tier or an old naming scheme |
