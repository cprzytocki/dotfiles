#!/bin/bash
# Launches all API services in a tmux session with panes in a single window.
# Usage: ./ankored-api.sh [start|stop] [--here]
#   --here  use the current tmux session (and its repo, if it has api/src)
#           instead of the dedicated ankored-app session

SESSION="ankored-app"
WINDOW="api"
API_ROOT="$HOME/git/ankored-app/api/src"
HERE=0

parse_args() {
    ACTION="start"
    for arg in "$@"; do
        case "$arg" in
            --here)      HERE=1 ;;
            start|stop)  ACTION="$arg" ;;
            *)           echo "Usage: $0 [start|stop] [--here]"; exit 1 ;;
        esac
    done

    if [ "$HERE" -eq 1 ]; then
        if [ -z "$TMUX" ]; then
            echo "--here requires being inside a tmux session"
            exit 1
        fi
        SESSION="$(tmux display-message -p '#S')"

        # Use this session's repo if it looks like the monorepo
        local root
        root=$(git -C "$(tmux display-message -p '#{session_path}')" rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$root" ] && [ -d "$root/api/src" ]; then
            API_ROOT="$root/api/src"
        fi
    fi
}

stop_session() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "No $SESSION session running"
        return
    fi

    if tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -q "^${WINDOW}$"; then
        tmux kill-window -t "$SESSION:$WINDOW"
        echo "Stopped $WINDOW"
    else
        echo "No $WINDOW window in $SESSION"
    fi
}

start_session() {
    local target="$SESSION:$WINDOW"

    # Create session if it doesn't exist
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -n "$WINDOW"
    elif tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -q "^${WINDOW}$"; then
        echo "$WINDOW window already exists"
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$target"
        else
            tmux attach -t "$target"
        fi
        return
    elif [ "$HERE" -eq 0 ] && [ -n "$TMUX" ] && [ "$(tmux display-message -p '#S')" = "$SESSION" ]; then
        # Already in the ankored-app session — reuse the current window
        tmux rename-window "$WINDOW"
    else
        # --here (or an unattached session): add a window, leave existing ones alone
        tmux new-window -t "$SESSION" -n "$WINDOW"
    fi

    # Top-left: IdentityServer (initial pane)
    tmux send-keys -t "$target" \
        "cd '$API_ROOT/AnkoredApi.IdentityServer' && ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=https://localhost:44383 dotnet run" Enter

    # Top-right: HttpApiHost (split right, new pane is active)
    tmux split-window -h -t "$target"
    tmux send-keys -t "$target" \
        "cd '$API_ROOT/AnkoredApi.HttpApi.Host' && ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=https://localhost:44332 DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true dotnet watch run" Enter

    # Bottom-left: BackgroundJobs (go back to left pane, split down)
    tmux select-pane -t "$target" -L
    tmux split-window -v -t "$target"
    tmux send-keys -t "$target" \
        "cd '$API_ROOT/AnkoredApi.BackgroundJobRunner' && DOTNET_ENVIRONMENT=Development DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true dotnet watch run" Enter

    # Bottom-right: Azurite (go to top-right pane, split down)
    tmux select-pane -t "$target" -U
    tmux select-pane -t "$target" -R
    tmux split-window -v -t "$target"
    tmux send-keys -t "$target" \
        "azurite --location $HOME/.AzureToolsForIntelliJ/azurite --loose --skipApiVersionCheck --cert $HOME/certs/localhost+1.pem --key $HOME/certs/localhost+1-key.pem" Enter

    # Focus back on top-left
    tmux select-pane -t "$target" -U
    tmux select-pane -t "$target" -L

    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$target"
    else
        tmux attach -t "$target"
    fi
}

parse_args "$@"

case "$ACTION" in
    stop)  stop_session ;;
    start) start_session ;;
esac
