#!/usr/bin/env bash
#
# launchd entry for the API server: stage 2 of scripts/start.sh as a foreground process
# launchd can keep alive. The same setting() resolution start.sh uses (environment, then
# .env, then the default), so the two never disagree about a port or a token; `exec` so
# the process launchd supervises is bun itself, not this shell.
#
# Bootstrap: launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mwp.openbot-server.plist

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
mkdir -p "$ROOT/.logs"

setting() {
  local name="$1" fallback="$2" value="${!1:-}"
  if [ -z "$value" ]; then
    value="$(grep -E "^$name=" "$ROOT/.env" | tail -1 | cut -d= -f2- | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
  fi
  printf '%s' "${value:-$fallback}"
}

SERVER_PORT="$(setting SERVER_PORT 3001)"
SUPERVISOR_PORT="$(setting SUPERVISOR_PORT 4500)"
SUPERVISOR_TOKEN="$(setting SUPERVISOR_TOKEN openbot-dev-supervisor-token)"
COMPUTER_TOKEN="$(setting COMPUTER_TOKEN openbot-dev-computer-token)"
WORKER_SHARED_SECRET="$(setting WORKER_SHARED_SECRET openbot-dev-worker-secret)"

BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

cd server
exec env PORT="$SERVER_PORT" \
  COMPUTER_SUPERVISOR_URL="http://localhost:$SUPERVISOR_PORT" \
  SUPERVISOR_TOKEN="$SUPERVISOR_TOKEN" \
  COMPUTER_TOKEN="$COMPUTER_TOKEN" \
  WORKER_SHARED_SECRET="$WORKER_SHARED_SECRET" \
  "$BUN" --env-file=../.env src/production-entry.ts
