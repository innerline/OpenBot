#!/usr/bin/env bash
#
# launchd entry for the routine-sweep worker: the exact launch scripts/start.sh performs
# (env resolved the same env → .env → default way), as a foreground process launchd can
# keep alive. Started from $ROOT with `bun worker/src/index.ts` — the same
# deliberately-specific argv start.sh uses, so pgrep/pkill guards match either starter.
#
# The worker never exits on a failed sweep (every phase is its own try/catch in
# worker/src/index.ts), so boot ordering against the server needs no coordination: a
# dispatch that lands before the server is up is logged and retried on the next tick.
#
# Bootstrap: launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mwp.openbot-worker.plist

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
WORKER_SHARED_SECRET="$(setting WORKER_SHARED_SECRET openbot-dev-worker-secret)"
WORKER_DATABASE_URL="$(setting DATABASE_URL postgres://openbot:openbot@localhost:5432/openbot)"

BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

exec env DATABASE_URL="$WORKER_DATABASE_URL" \
  SERVER_INTERNAL_URL="http://localhost:$SERVER_PORT" \
  WORKER_SHARED_SECRET="$WORKER_SHARED_SECRET" \
  "$BUN" worker/src/index.ts
