#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
context_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

cd "$cwd" 2>/dev/null
git_branch=$(git branch --show-current 2>/dev/null)

status="$model"
dir_display="${cwd/#$HOME/~}"
status="$status | $dir_display"
[ -n "$git_branch" ] && status="$status | git:$git_branch"
[ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ] && status="$status | +$lines_added-$lines_removed"
[ -n "$context_remaining" ] && status="$status | context:${context_remaining}%"

echo "$status"
