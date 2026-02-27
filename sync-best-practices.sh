#!/bin/bash
# Sync best practices from brave-core-tools to src/brave/.claude/rules via symlink

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BP_SRC="$SCRIPT_DIR/docs/best-practices"

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

BP_DEST="$BRAVE_ROOT/src/brave/.claude/rules/best-practices"

if [ ! -d "$BP_SRC" ]; then
  echo "No best practices found in $BP_SRC"
  exit 1
fi

# If it's already a valid symlink, nothing to do
if [ -L "$BP_DEST" ] && [ -e "$BP_DEST" ]; then
  echo "Already symlinked: $BP_DEST -> $(readlink "$BP_DEST")"
  exit 0
fi

# Clean up broken symlink or directory of old per-file symlinks
if [ -L "$BP_DEST" ]; then
  echo "Removing broken symlink: $BP_DEST"
  rm "$BP_DEST"
elif [ -d "$BP_DEST" ]; then
  echo "Removing old per-file symlinks directory: $BP_DEST"
  rm -rf "$BP_DEST"
fi

mkdir -p "$(dirname "$BP_DEST")"
ln -s "../../../../brave-core-tools/docs/best-practices" "$BP_DEST"
echo "Linked: $BP_DEST -> ../../../../brave-core-tools/docs/best-practices"
