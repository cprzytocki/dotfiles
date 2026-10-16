#!/bin/bash
# Connect to an fzf selection from the sesh picker.
# Usage: sesh-connect.sh <fzf-selection>
#   Handles both icon-prefixed sesh entries ("icon name") and plain paths ("~/git/...")
#   sesh names a session after the directory basename, so two checkouts of the same
#   repo resolve to one session. When that name is taken by a different path, the
#   parent directory is prepended instead.
selection="$1"
[ -n "$selection" ] || exit 0

case "$selection" in
  '~/'* | /*) target="$selection" ;;
  *) target="${selection#* }" ;;
esac

# Not a path: it's a tmux or config entry, sesh already knows the name
case "$target" in
  '~/'* | /*) ;;
  *) exec sesh connect "$selection" ;;
esac

path="${target/#\~/$HOME}"
path="${path%/}"
[ -d "$path" ] || exec sesh connect "$selection"

sanitize() { printf '%s' "${1//[.:]/_}"; }

switch_to() {
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "=$1"
  else
    tmux attach-session -t "=$1"
  fi
}

# Already open at this exact path, whatever it ended up being called
open=$(tmux list-sessions -F '#{session_path}	#{session_name}' 2>/dev/null |
  awk -F'\t' -v p="$path" '$1 == p { print $2; exit }')
if [ -n "$open" ]; then
  switch_to "$open"
  exit
fi

base=$(basename "$path")
if ! tmux has-session -t "=$(sanitize "$base")" 2>/dev/null; then
  exec sesh connect "$selection"
fi

name=$(sanitize "$(basename "$(dirname "$path")")_$base")
if ! tmux has-session -t "=$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -c "$path"
  startup=$(awk '
    /^\[/ { default_section = ($0 ~ /^\[default_session\]/); next }
    default_section && /^[[:space:]]*startup_command[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; exit
    }
  ' "${XDG_CONFIG_HOME:-$HOME/.config}/sesh/sesh.toml" 2>/dev/null)
  [ -n "$startup" ] && tmux send-keys -t "=$name:" "$startup" Enter
fi
switch_to "$name"
