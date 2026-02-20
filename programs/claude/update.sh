#!/usr/bin/env bash
# Claude Code flake updater
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

echo "Fetching latest version..."
VERSION=$(curl -fsSL "$BASE_URL/latest")
echo "Latest version: $VERSION"

CURRENT_VERSION=$(jq -r '.version' "$SCRIPT_DIR/manifest.json" 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"

if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already up to date!"
  exit 0
fi

echo "Downloading manifest for $VERSION..."
curl -fsSL "$BASE_URL/$VERSION/manifest.json" -o "$SCRIPT_DIR/manifest.json"

echo "Updated to $VERSION!"
echo ""
echo "Don't forget to run:"
echo "  nix flake update && git add -A && home-manager switch"
