#!/usr/bin/env bash
# multi-agent-shogun updater
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

echo "Fetching latest multi-agent-shogun version..."
VERSION=$(gh api repos/yohey-w/multi-agent-shogun/tags --jq '.[0].name' | sed 's/^v//')
echo "Latest version: $VERSION"

CURRENT_VERSION=$(grep 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo "Current version: $CURRENT_VERSION"

if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already up to date!"
  exit 0
fi

echo "Calculating hash for v${VERSION}..."
RAW_HASH=$(nix-prefetch-url --unpack "https://github.com/yohey-w/multi-agent-shogun/archive/refs/tags/v${VERSION}.tar.gz" 2>/dev/null)
HASH=$(nix hash convert --hash-algo sha256 --to sri "$RAW_HASH")

echo "Updating package.nix..."
sed -i '' "s/version = \"${CURRENT_VERSION}\"/version = \"${VERSION}\"/" "$PACKAGE_NIX"
sed -i '' "s|hash = \"sha256-.*\"|hash = \"${HASH}\"|" "$PACKAGE_NIX"

echo "Updated to $VERSION!"
echo ""
echo "Don't forget to run:"
echo "  git add -A && nix flake update && home-manager switch"
