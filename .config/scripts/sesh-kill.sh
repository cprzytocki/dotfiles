#!/bin/bash
# Kill a sesh/tmux session.
# Usage: sesh-kill.sh <fzf-selection>
#   Handles both icon-prefixed sesh entries ("icon name") and plain paths ("~/git/...")
#   A path entry resolves to whatever session is open there, since sesh-connect.sh
#   renames a session when its basename is already taken.
selection="$1"
[ -n "$selection" ] || exit 0

case "$selection" in
  '~/'* | /*) target="$selection" ;;
  *) target="${selection#* }" ;;
esac

case "$target" in
  '~/'* | /*)
    path="${target/#\~/$HOME}"
    path="${path%/}"
    session=$(tmux list-sessions -F '#{session_path}	#{session_name}' 2>/dev/null |
      awk -F'\t' -v p="$path" '$1 == p { print $2; exit }')
    ;;
  *)
    session="$target"
    ;;
esac

if [ -n "$session" ]; then
  tmux kill-session -t "=$session" 2>/dev/null
fi

exit 0
