#!/usr/bin/env bash
set -euo pipefail

# Clean up ~/.claude/*.backup.* files created by sync-config.sh
# Usage:
#   ./clean-config-backups.sh        # delete all backups
#   ./clean-config-backups.sh 3      # keep 3 most recent
#   DRY_RUN=1 ./clean-config-backups.sh

KEEP_COUNT=${1:-0}
DRY_RUN=${DRY_RUN:-}

backups=$(find "$HOME/.claude" -type f -name "*.backup.*" 2>/dev/null | sort -r || true)
[ -z "$backups" ] && { echo "No backups found"; exit 0; }

[ "$KEEP_COUNT" -gt 0 ] && backups=$(echo "$backups" | tail -n +$((KEEP_COUNT + 1)))
[ -z "$backups" ] && { echo "Keeping $KEEP_COUNT most recent, nothing to delete"; exit 0; }

deleted=0
while IFS= read -r file; do
  if [ -n "$DRY_RUN" ]; then
    echo "[DRY RUN] would delete $file"
  else
    rm -f "$file"
    echo "removed $file"
  fi
  ((deleted++))
done <<< "$backups"

echo "$deleted backup(s) $([ -n "$DRY_RUN" ] && echo "would be removed" || echo "removed")"
