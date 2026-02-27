#!/bin/bash
# Sync skills from brave-core-tools to src/brave via symlinks
# Each skill is prompted individually so you can choose which ones to share

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/.claude/skills"

# Detect brave-browser root
if [ -d "$SCRIPT_DIR/../src/brave" ]; then
  BRAVE_ROOT="$SCRIPT_DIR/.."
elif [ -d "$SCRIPT_DIR/../../src/brave" ]; then
  # Running from brave-core-bot/brave-core-tools/ (submodule)
  BRAVE_ROOT="$SCRIPT_DIR/../.."
else
  echo "Cannot find src/brave. Expected to be at brave-browser/brave-core-tools/"
  exit 1
fi

SKILLS_DEST="$BRAVE_ROOT/src/brave/.claude/skills"

if [ ! -d "$SKILLS_SRC" ]; then
  echo "No skills found in $SKILLS_SRC"
  exit 1
fi

# Create destination directory if needed
mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  dest="$SKILLS_DEST/$skill_name"

  if [ -L "$dest" ]; then
    if [ -e "$dest" ]; then
      echo "✓ $skill_name (already symlinked)"
      continue
    else
      echo "⚠ $skill_name (broken symlink, recreating)"
      rm "$dest"
    fi
  fi

  if [ -d "$dest" ]; then
    echo "⚠ $skill_name (exists as regular directory, skipping)"
    continue
  fi

  read -p "Symlink $skill_name? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -s "../../../../brave-core-tools/.claude/skills/$skill_name" "$dest"
    echo "  ✓ Linked"
  else
    echo "  ✗ Skipped"
  fi
done

echo ""
echo "Done. Current symlinks in $SKILLS_DEST:"
ls -la "$SKILLS_DEST" | grep "^l" || echo "  (none)"
