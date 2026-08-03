#!/usr/bin/env bash
set -euo pipefail

# ai-toolkit bootstrap

REPO_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

# 1. Claude Code settings.json (model, hooks, plugins) — repo is source of truth
read -p "Sync ~/.claude/settings.json from this repo? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  bash "$REPO_SCRIPTS/sync-config.sh"
fi

echo ""

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi

echo ""

# 3. RTK: token-saving CLI proxy.
# `rtk init -g --auto-patch` creates filters.toml + ~/.claude/RTK.md,
# adds @RTK.md to the global CLAUDE.md and patches the PreToolUse hook
# into ~/.claude/settings.json.
echo "Setting up RTK..."
if ! command -v rtk &>/dev/null; then
  echo "RTK not found, installing..."
  brew install rtk
fi
rtk init -g --auto-patch
echo "RTK configured ($(rtk --version))."

echo ""

# 4. Skills
echo "Cleaning up broken skill symlinks..."
bash "$REPO_SCRIPTS/unlink-skills.sh"
echo "Linking skills..."
bash "$REPO_SCRIPTS/link-skills.sh"

echo ""

# 5. MCP servers
if ! command -v claude &>/dev/null; then
  echo "'claude' CLI not found."
  if command -v npm &>/dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
  else
    echo "WARNING: npm not found. Install Claude Code first:"
    echo "    npm install -g @anthropic-ai/claude-code"
    echo "    or see https://docs.claude.com/en/docs/claude-code/setup"
  fi
fi

if command -v claude &>/dev/null; then
  echo "Registering MCP servers..."
  bash "$REPO_SCRIPTS/sync-mcp.sh"
else
  echo "Skipping MCP server registration (claude CLI unavailable)."
fi

echo ""

# 6. OpenSpec
if command -v npm &>/dev/null; then
  echo "Installing OpenSpec..."
  npm install -g @fission-ai/openspec@latest
  echo "OpenSpec installed. Run 'openspec init' inside each project to enable planning."
else
  echo "WARNING: npm not found. OpenSpec not installed."
  echo "    Install Node.js first, then: npm install -g @fission-ai/openspec@latest"
fi

echo ""

# 7. CodeGraph
if command -v npm &>/dev/null; then
  echo "Installing CodeGraph..."
  npm install -g @colbymchenry/codegraph
  codegraph install
  echo "CodeGraph installed. Run 'codegraph init' inside each project to build its graph."
else
  echo "WARNING: npm not found. CodeGraph not installed."
  echo "    Install Node.js first, then: npm install -g @colbymchenry/codegraph"
fi

echo ""

# 8. Headroom: local token-compression proxy for Claude Code's own API traffic
# (complements RTK, which only rewrites shell commands). `headroom init -g claude`
# patches ~/.claude/settings.json with the hooks/env/plugin this repo's
# settings.json already mirrors.
echo "Setting up Headroom..."
if ! command -v uv &>/dev/null; then
  echo "uv not found, installing..."
  brew install uv
fi
uv tool install --python 3.13 "headroom-ai[all]"
headroom init -g claude
echo "Headroom configured ($(headroom --version))."

echo ""

# 9. Caveman: ultra-compressed communication mode
# Runs from $HOME: with Codex present, its installer drops project-local
# skill files (.agents/skills, skills-lock.json) into the cwd instead of a
# global dir, which would otherwise leak into whatever repo we're run from.
if command -v node &>/dev/null; then
  echo "Installing Caveman..."
  (cd "$HOME" && curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash)
else
  echo "WARNING: node not found. Caveman not installed."
  echo "    Install Node.js first, then: curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash"
fi
