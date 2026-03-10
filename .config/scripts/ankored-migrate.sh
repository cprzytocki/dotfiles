#!/usr/bin/env bash
set -e

ROOT="$HOME/git/ankored-api"

echo "Running database migrations..."
(cd "$ROOT/src/AnkoredApi.DbMigrator" && dotnet run)
