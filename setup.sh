#!/bin/bash
# Setup script for brave-core-tools
# Run this to set up skills and best practices for brave-core development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================="
echo "  Brave Core Tools Setup"
echo "==================================="
echo ""

# Validate directory structure
if [ -d "$SCRIPT_DIR/../src/brave" ]; then
  BRAVE_ROOT="$SCRIPT_DIR/.."
elif [ -d "$SCRIPT_DIR/../../src/brave" ]; then
  BRAVE_ROOT="$SCRIPT_DIR/../.."
else
  echo "Warning: Expected directory structure not found"
  echo ""
  echo "This script expects to be run from:"
  echo "  brave-browser/brave-core-tools/"
  echo ""
  echo "Where brave-browser contains:"
  echo "  - src/brave/ (target git repository)"
  echo "  - brave-core-tools/ (this directory)"
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
  fi
fi

# Sync skills
echo "Syncing skills to src/brave/.claude/skills/..."
"$SCRIPT_DIR/sync-skills.sh"
echo ""

# Sync best practices
echo "Syncing best practices to src/brave/.claude/rules/..."
"$SCRIPT_DIR/sync-best-practices.sh"
echo ""

echo "==================================="
echo "  Setup Complete!"
echo "==================================="
echo ""
echo "Skills and best practices are now available in src/brave."
echo "You can invoke skills like /review, /preflight, /commit, etc."
echo ""
