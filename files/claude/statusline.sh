#!/bin/bash
input=$(cat)

PERCENT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')

# Directory name
DIR_NAME=$(basename "$DIR")

# Git branch (with dirty marker)
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ] && [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
  BRANCH="${BRANCH}*"
fi

# Context usage color
if (( $(echo "$PERCENT_USED < 50" | bc -l) )); then
  COLOR="\033[32m"
elif (( $(echo "$PERCENT_USED < 80" | bc -l) )); then
  COLOR="\033[33m"
else
  COLOR="\033[31m"
fi
RESET="\033[0m"

printf "Context: ${COLOR}%.1f%%${RESET} | %s%s" \
  "$PERCENT_USED" "$DIR_NAME" "${BRANCH:+ | $BRANCH}"
