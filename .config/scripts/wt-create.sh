#!/bin/bash
# Create a worktree and open it as a sesh session.
# Usage: wt-create.sh <repo-path> <branch-name>
cd "$1" || exit 1
wt switch -c "$2" --no-cd -y 2>&1

# Find the new worktree path from git
new_path=$(git worktree list --porcelain | awk -v branch="$2" '
  /^worktree / { path = substr($0, 10) }
  /^branch / { b = $0; sub(/.*refs\/heads\//, "", b); if (b == branch) print path }
')

if [ -n "$new_path" ]; then
  sesh connect "$new_path"
fi
