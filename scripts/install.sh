#!/usr/bin/env bash
set -euo pipefail

# ai-toolkit bootstrap

if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi

# RTK: token-saving CLI proxy.
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
