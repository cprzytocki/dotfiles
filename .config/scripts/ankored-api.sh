#!/usr/bin/env bash
set -e

ROOT="$HOME/git/ankored-api"

cleanup() {
    echo "Stopping all services..."
    trap '' TERM INT
    kill 0
    wait
    echo "All services stopped."
    exit 0
}
trap cleanup INT TERM

# Kill any leftover processes on our ports
for port in 44332 44383 10000 10001 10002; do
    lsof -ti :"$port" | xargs kill 2>/dev/null || true
done

echo "Starting Azurite..."
(cd ~ && exec azurite --cert ~/certs/localhost+1.pem --key ~/certs/localhost+1-key.pem -s -l ~/azurite -d ~/azurite/debug.log) &

echo "Building solution..."
dotnet build "$ROOT/AnkoredApi.sln"

echo "Starting IdentityServer on https://localhost:44383..."
(cd "$ROOT/src/AnkoredApi.IdentityServer" && exec dotnet run --no-build) &

echo "Starting API on https://localhost:44332..."
(cd "$ROOT/src/AnkoredApi.HttpApi.Host" && exec dotnet run --no-build) &

echo "Starting BackgroundJobRunner..."
(cd "$ROOT/src/AnkoredApi.BackgroundJobRunner" && exec dotnet run --no-build) 2>&1 | grep -v "distributed lock\|recurring job.*processed\|heartbeat successfully\|Executing.*Worker\|Skipping.*Worker" &

echo ""
echo "All 4 services started. Press Ctrl+C to stop."
wait
