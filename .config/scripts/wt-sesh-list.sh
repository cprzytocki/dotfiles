#!/bin/bash
# List all worktree paths across repos in ~/git/ for the sesh fzf picker.
# Outputs ~/... relative paths so sesh connect works natively.
for repo in ~/git/*/; do
  [ -d "$repo/.git" ] || continue
  git -C "$repo" worktree list --porcelain 2>/dev/null | while read line; do
    case "$line" in
      "worktree "*)
        wt_path="${line#worktree }"
        echo "${wt_path/#$HOME/~}"
        ;;
    esac
  done
done
