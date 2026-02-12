#!/bin/bash

# Usage: rebase <baseBranch> <numberOfCommits>
# sourceBranch is inferred from the current checked-out branch

set -e

baseBranch="$1"
numCommits="$2"
currentBranch=$(git rev-parse --abbrev-ref HEAD)

if [ -z "$baseBranch" ] || [ -z "$numCommits" ]; then
  echo "Usage: rebase <baseBranch> <numberOfCommits>"
  exit 1
fi

echo "Current branch is: $currentBranch"
echo "Rebasing $currentBranch onto $baseBranch starting from $currentBranch~$numCommits"

git rebase --onto "$baseBranch" "$currentBranch~$numCommits" "$currentBranch"