#!/bin/bash
input=$(cat)

PERCENT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')

# Directory name
DIR_NAME=$(basename "$DIR")

# Git branch (with dirty marker, worktree-aware)
BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "HEAD" ]; then
  BRANCH=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
fi
if [ -n "$BRANCH" ]; then
  # Check if in a worktree
  GIT_DIR=$(git -C "$DIR" rev-parse --git-dir 2>/dev/null)
  GIT_COMMON_DIR=$(git -C "$DIR" rev-parse --git-common-dir 2>/dev/null)
  if [ "$GIT_DIR" != "$GIT_COMMON_DIR" ]; then
    BRANCH="wt:${BRANCH}"
  fi
  if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
    BRANCH="${BRANCH}*"
  fi
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
