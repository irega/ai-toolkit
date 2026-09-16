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

# 3. Skills
echo "Cleaning up broken skill symlinks..."
bash "$REPO_SCRIPTS/unlink-skills.sh"
echo "Linking skills..."
bash "$REPO_SCRIPTS/link-skills.sh"

echo ""

# 4. MCP servers (registers into whichever of claude/codex/opencode are installed)
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

echo "Registering MCP servers..."
bash "$REPO_SCRIPTS/mcp/sync-mcp.sh"

echo ""

# 4b. OpenCode pinned agents: delivery-workflow's tiers.json becomes one
# pinned subagent per tier (OpenCode's task tool can't override model
# per-call, so pinning it in the agent's frontmatter is the only channel).
if command -v opencode &>/dev/null; then
  echo "Generating OpenCode pinned agents from tiers.json..."
  bash "$REPO_SCRIPTS/opencode/sync-opencode-agents.sh"
else
  echo "Skipping OpenCode pinned agents ('opencode' CLI not found)"
fi

echo ""

# 5. OpenSpec
if command -v npm &>/dev/null; then
  echo "Installing OpenSpec..."
  npm install -g @fission-ai/openspec@latest
  echo "OpenSpec installed. Run 'openspec init' inside each project to enable planning."
else
  echo "WARNING: npm not found. OpenSpec not installed."
  echo "    Install Node.js first, then: npm install -g @fission-ai/openspec@latest"
fi

echo ""

# 6. CodeGraph
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

# 7. GitHub CLI: used by Claude Code for PRs, issues, checks, releases
if ! command -v gh &>/dev/null; then
  echo "gh not found, installing..."
  brew install gh
fi
echo "gh configured ($(gh --version | head -1))."

echo ""

# 8. Humanizer: rewrites AI-sounding prose, cross-agent skill
if command -v npx &>/dev/null; then
  echo "Installing Humanizer..."
  npx --yes skills add blader/humanizer --global -y
else
  echo "WARNING: npx not found. Humanizer not installed."
  echo "    Install Node.js first, then: npx skills add blader/humanizer --global -y"
fi

echo ""

# 9. Ponytail: lazy/minimal-code coding skill, cross-agent skill
if command -v npx &>/dev/null; then
  echo "Installing Ponytail..."
  npx --yes skills add DietrichGebert/ponytail --global -y
else
  echo "WARNING: npx not found. Ponytail not installed."
  echo "    Install Node.js first, then: npx skills add DietrichGebert/ponytail --global -y"
fi

echo ""

# 10. Superpowers: brainstorming/TDD/debugging process skills, cross-agent
if command -v npx &>/dev/null; then
  echo "Installing Superpowers..."
  npx --yes skills add obra/superpowers --global -y
else
  echo "WARNING: npx not found. Superpowers not installed."
  echo "    Install Node.js first, then: npx skills add obra/superpowers --global -y"
fi

echo ""

# 11. HumanLayer show-me: explains topics with diagrams/HTML artifacts, cross-agent skill
if command -v npx &>/dev/null; then
  echo "Installing HumanLayer show-me..."
  npx --yes skills add humanlayer/skills --skill show-me --global -y
else
  echo "WARNING: npx not found. HumanLayer show-me not installed."
  echo "    Install Node.js first, then: npx skills add humanlayer/skills --skill show-me --global -y"
fi

echo ""

# 12. Caveman: ultra-compressed communication mode
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

echo ""

# 13. Engram: persistent memory MCP server, cross-agent
echo "Setting up Engram..."
if ! command -v engram &>/dev/null; then
  echo "Engram not found, installing..."
  brew install gentleman-programming/tap/engram
fi
if command -v claude &>/dev/null; then
  claude plugin marketplace add Gentleman-Programming/engram
  claude plugin install engram
fi
if command -v codex &>/dev/null; then
  engram setup codex
fi
if command -v opencode &>/dev/null; then
  engram setup opencode
fi
echo "Engram configured ($(engram version 2>/dev/null || echo installed))."

echo ""

# 14. CodeBurn: local AI coding token and cost tracking
if command -v npm &>/dev/null; then
  echo "Installing CodeBurn..."
  npm install -g codeburn
  echo "CodeBurn installed ($(codeburn --version 2>/dev/null || echo installed))."
else
  echo "WARNING: npm not found. CodeBurn not installed."
  echo "    Install Node.js first, then: npm install -g codeburn"
fi
