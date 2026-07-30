#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Verified PR Review
# @raycast.mode silent
# @raycast.packageName Ankored
# @raycast.icon 🔍
# @raycast.argument1 { "type": "text", "placeholder": "PR URL" }
#
# Opens a new window in the ankored-app_reviews tmux session and launches
# Claude in auto mode running the verified-review slash command on the given PR.
# Usage: ./ankored-review.sh <pr-url>

SESSION="ankored-app_reviews"
REPO="$HOME/git/ankored-app.reviews"

PR_URL="$1"
if [ -z "$PR_URL" ]; then
    echo "Usage: $0 <pr-url>"
    exit 1
fi

# Window name from the PR number (.../pull/1234 -> review-1234), else "review".
PR_NUM="$(echo "$PR_URL" | grep -oE '[0-9]+' | tail -1)"
WINDOW="review${PR_NUM:+-$PR_NUM}"

# Create the session detached if it isn't already up.
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION"
fi

# Fresh window each launch, started in the repo so verified-review has context.
# Capture the unique window id and target that for everything below — the window
# name gets auto-renamed by the running program, so name lookups can race.
WIN_ID="$(tmux new-window -P -F '#{window_id}' -t "$SESSION" -n "$WINDOW" -c "$REPO")"
# Keep the review-<num> label visible instead of letting claude rename it.
tmux set-window-option -t "$WIN_ID" automatic-rename off
tmux send-keys -t "$WIN_ID" \
    "claude --permission-mode auto '/verified-review $PR_URL'" Enter

# Focus the new window.
tmux select-window -t "$WIN_ID"
if [ -n "$TMUX" ]; then
    tmux switch-client -t "$WIN_ID"
else
    # Launched from outside tmux (e.g. Raycast). Reuse an existing tmux client
    # (likely attached to another session) by switching it to our window, then
    # raise Ghostty. Only spawn a terminal if nothing is attached at all.
    client="$(tmux list-clients -F '#{client_name}' 2>/dev/null | head -1)"
    if [ -n "$client" ]; then
        tmux switch-client -c "$client" -t "$WIN_ID"
        open -a Ghostty
    else
        open -a Ghostty -n --args -e tmux new-session -A -s "$SESSION"
    fi
fi
