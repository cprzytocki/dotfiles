#!/bin/bash
# Launches all API services in a tmux session with named windows.
# Usage: ./api-services.sh [start|stop]

SESSION="ankored-api"
API_ROOT="$HOME/git/ankored-api/src"

stop_session() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "No $SESSION session running"
        return
    fi

    for win in IdentityServer HttpApiHost BackgroundJobs Azurite; do
        if has_window "$win"; then
            tmux kill-window -t "$SESSION:$win"
            echo "Stopped $win"
        fi
    done
}

has_window() {
    tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -q "^$1$"
}

ensure_windows() {
    # Window 1: IdentityServer
    if ! has_window "IdentityServer"; then
        tmux new-window -t "$SESSION" -n "IdentityServer"
        tmux send-keys -t "$SESSION:IdentityServer" \
            "cd '$API_ROOT/AnkoredApi.IdentityServer' && ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=https://localhost:44383 dotnet run" Enter
    fi

    # Window 2: HttpApiHost (hot reload)
    if ! has_window "HttpApiHost"; then
        tmux new-window -t "$SESSION" -n "HttpApiHost"
        tmux send-keys -t "$SESSION:HttpApiHost" \
            "cd '$API_ROOT/AnkoredApi.HttpApi.Host' && ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=https://localhost:44332 DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true dotnet watch run" Enter
    fi

    # Window 3: BackgroundJobRunner (hot reload)
    if ! has_window "BackgroundJobs"; then
        tmux new-window -t "$SESSION" -n "BackgroundJobs"
        tmux send-keys -t "$SESSION:BackgroundJobs" \
            "cd '$API_ROOT/AnkoredApi.BackgroundJobRunner' && DOTNET_ENVIRONMENT=Development DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true dotnet watch run" Enter
    fi

    # Window 4: Azurite
    if ! has_window "Azurite"; then
        tmux new-window -t "$SESSION" -n "Azurite"
        tmux send-keys -t "$SESSION:Azurite" \
            "azurite --location $HOME/.AzureToolsForIntelliJ/azurite --loose --skipApiVersionCheck --cert $HOME/certs/localhost+1.pem --key $HOME/certs/localhost+1-key.pem" Enter
    fi
}

start_session() {
    # Create session if it doesn't exist
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION"
    fi

    ensure_windows

    tmux select-window -t "$SESSION:IdentityServer"

    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
}

case "${1:-start}" in
    stop)  stop_session ;;
    start) start_session ;;
    *)     echo "Usage: $0 [start|stop]" ;;
esac
