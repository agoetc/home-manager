#!/bin/sh
set -e

# 1. リポジトリを ~/.config/home-manager/ にコピー
echo "==> Copying to ~/.config/home-manager/ ..."
cp -r ./ ~/.config/home-manager/

# 2. age 秘密鍵のセットアップ
AGE_DIR="$HOME/Library/Application Support/sops/age"
AGE_KEY="$AGE_DIR/keys.txt"

if [ -f "$AGE_KEY" ]; then
  echo "==> age key already exists at: $AGE_KEY"
  printf "    Overwrite? [y/N]: "
  read -r answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "    Skipped."
  else
    printf "==> Paste your age secret key (AGE-SECRET-KEY-...): "
    read -r key
    if [ -n "$key" ]; then
      echo "$key" > "$AGE_KEY"
      chmod 600 "$AGE_KEY"
      echo "    Saved."
    fi
  fi
else
  mkdir -p "$AGE_DIR"
  printf "==> Paste your age secret key (AGE-SECRET-KEY-...): "
  read -r key
  if [ -n "$key" ]; then
    echo "$key" > "$AGE_KEY"
    chmod 600 "$AGE_KEY"
    echo "    Saved to: $AGE_KEY"
  else
    echo "    Skipped. Secrets will not be decrypted."
  fi
fi

# 3. home-manager 適用
echo "==> Applying home-manager configuration ..."
cd ~/.config/home-manager
git add -A && nix flake update && home-manager switch

echo "==> Done!"
