#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
PERCENT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')

# Directory name
DIR_NAME=$(basename "$DIR")

# Git branch
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)

# Context usage color
if (( $(echo "$PERCENT_USED < 50" | bc -l) )); then
  COLOR="\033[32m"
elif (( $(echo "$PERCENT_USED < 80" | bc -l) )); then
  COLOR="\033[33m"
else
  COLOR="\033[31m"
fi
RESET="\033[0m"

printf "📂 %s%s | %s ${COLOR}%.1f%%${RESET}" \
  "$DIR_NAME" "${BRANCH:+ | 🌿 $BRANCH}" "$MODEL" "$PERCENT_USED"
