#!/bin/bash
# Launches all API services in a tmux session with named windows.
# Usage: ./api-services.sh [start|stop]

SESSION="api-services"
API_ROOT="$HOME/git/ankored-api/src"

stop_session() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux kill-session -t "$SESSION"
        echo "Stopped $SESSION"
    else
        echo "No $SESSION session running"
    fi
}

start_session() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "Session $SESSION already running. Switching..."
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$SESSION"
        else
            tmux attach -t "$SESSION"
        fi
        return
    fi

    # Window 1: IdentityServer
    tmux new-session -d -s "$SESSION" -n "IdentityServer" \
        "cd '$API_ROOT/AnkoredApi.IdentityServer' && \
         ASPNETCORE_ENVIRONMENT=Development \
         ASPNETCORE_URLS=https://localhost:44383 \
         dotnet run; read -p 'Press Enter to close...'"

    # Window 2: HttpApi.Host (hot reload)
    tmux new-window -t "$SESSION" -n "HttpApi.Host" \
        "cd '$API_ROOT/AnkoredApi.HttpApi.Host' && \
         ASPNETCORE_ENVIRONMENT=Development \
         ASPNETCORE_URLS=https://localhost:44332 \
         DOTNET_WATCH_RESTART_ON_RUDE_EDIT=true \
         dotnet watch run; read -p 'Press Enter to close...'"

    # Window 3: BackgroundJobRunner
    tmux new-window -t "$SESSION" -n "BackgroundJobs" \
        "cd '$API_ROOT/AnkoredApi.BackgroundJobRunner' && \
         DOTNET_ENVIRONMENT=Development \
         dotnet run; read -p 'Press Enter to close...'"

    # Window 4: Azurite
    tmux new-window -t "$SESSION" -n "Azurite" \
        "azurite --location $HOME/.AzureToolsForIntelliJ/azurite --loose --skipApiVersionCheck --cert $HOME/certs/localhost+1.pem --key $HOME/certs/localhost+1-key.pem; read -p 'Press Enter to close...'"

    # Start on the first window
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
