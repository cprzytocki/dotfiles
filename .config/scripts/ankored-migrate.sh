#!/usr/bin/env bash
set -e

ROOT="$HOME/git/ankored-app"

echo "Running database migrations..."
(cd "$ROOT/api/src/AnkoredApi.DbMigrator" && dotnet run)
