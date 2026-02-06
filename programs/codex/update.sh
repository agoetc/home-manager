#!/usr/bin/env bash
# Codex flake updater
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Fetching latest codex version..."
VERSION=$(gh api repos/openai/codex/tags --jq '.[].name' | grep -E '^rust-v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 | sed 's/^rust-v//')
echo "Latest version: $VERSION"

CURRENT_VERSION=$(jq -r '.version' "$SCRIPT_DIR/version.json" 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"

if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already up to date!"
  exit 0
fi

echo "Calculating hash for aarch64-darwin..."
HASH=$(nix-prefetch-url "https://github.com/openai/codex/releases/download/rust-v${VERSION}/codex-aarch64-apple-darwin.tar.gz" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)

cat > "$SCRIPT_DIR/version.json" <<EOF
{
  "version": "$VERSION",
  "platforms": {
    "aarch64-darwin": {
      "asset": "codex-aarch64-apple-darwin.tar.gz",
      "binary": "codex-aarch64-apple-darwin",
      "hash": "$HASH"
    }
  }
}
EOF

echo "Updated to $VERSION!"
echo ""
echo "Don't forget to run:"
echo "  git add -A && nix flake update && home-manager switch"
