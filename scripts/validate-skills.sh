#!/usr/bin/env bash
set -euo pipefail

# Validates skills/ structure: frontmatter, cross-links, tier mapping.
# Run before installing or opening a PR that touches skills/.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check() {
  echo "FAIL: $1"
  fail=1
}

# 1. Every SKILL.md has name/description frontmatter, name matches dir name.
while IFS= read -r -d '' skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"

  frontmatter="$(awk '/^---$/{c++; next} c==1' "$skill_md")"

  if ! echo "$frontmatter" | grep -q '^name:'; then
    check "$skill_md missing 'name:' in frontmatter"
  elif [ "$(echo "$frontmatter" | grep '^name:' | head -1 | sed 's/^name: *//')" != "$name" ]; then
    check "$skill_md 'name:' does not match directory name '$name'"
  fi

  if ! echo "$frontmatter" | grep -q '^description:'; then
    check "$skill_md missing 'description:' in frontmatter"
  fi

  # 2. Cross-links: any relative markdown link or bare path reference to a
  # file under the skill dir must resolve.
  while IFS= read -r ref; do
    ref="${ref#./}"
    target="$dir/$ref"
    if [ ! -e "$target" ]; then
      check "$skill_md references missing file '$ref'"
    fi
  done < <(grep -oE '\([./]*(references|scripts)/[A-Za-z0-9_./-]+\)' "$skill_md" | tr -d '()' | sort -u)
done < <(find "$REPO/skills" -name SKILL.md -print0)

# 3. Tier mapping is valid JSON and has the three required tiers.
tiers_json="$REPO/skills/delivery-workflow/tiers.json"
if [ -f "$tiers_json" ]; then
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$tiers_json" 2>/dev/null; then
    check "$tiers_json is not valid JSON"
  else
    for tier in high_reasoning standard economy; do
      if ! python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if sys.argv[2] in d.get('tiers', {}) else 1)" "$tiers_json" "$tier"; then
        check "$tiers_json missing required tier '$tier'"
      fi
    done
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "OK: skills validated."
else
  exit 1
fi
