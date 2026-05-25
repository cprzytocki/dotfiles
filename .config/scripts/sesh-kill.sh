#!/bin/bash
# Kill a sesh/tmux session. If it's a worktrunk worktree, remove that too.
# Usage: sesh-kill.sh <fzf-selection>
#   Handles both icon-prefixed sesh entries ("icon name") and plain paths ("~/git/...")
selection="$1"

if [[ "$selection" == ~/* ]] || [[ "$selection" == /* ]]; then
  # Worktree list entry: selection is a path
  path="${selection/#\~/$HOME}"

  # Remove worktree if applicable
  if [ -f "$path/.git" ]; then
    wt remove -y -C "$path" 2>/dev/null
  fi

  # Kill matching tmux session if one exists (sesh names sessions by path)
  tmux kill-session -t "$selection" 2>/dev/null
else
  # Sesh list entry: strip icon prefix to get session name
  session="${selection#* }"

  # Check if the session's directory is a worktree
  path=$(tmux display-message -p -t "$session" '#{session_path}' 2>/dev/null)
  if [ -n "$path" ] && [ -f "$path/.git" ]; then
    wt remove -y -C "$path" 2>/dev/null
  fi

  tmux kill-session -t "$session" 2>/dev/null
fi
