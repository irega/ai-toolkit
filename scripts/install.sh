#!/usr/bin/env bash
set -euo pipefail

# ai-toolkit bootstrap

REPO_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

# 1. Homebrew
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi

echo ""

# 2. RTK: token-saving CLI proxy.
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

# 3. Claude Code settings.json (model, hooks, plugins) — repo is source of truth
read -p "Sync ~/.claude/settings.json from this repo? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  bash "$REPO_SCRIPTS/sync-config.sh"
fi

echo ""

# 4. Skills
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
