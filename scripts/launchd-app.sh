#!/usr/bin/env bash
#
# launchd entry for the app (vite dev server): stage 4 of scripts/start.sh as a
# foreground process launchd can keep alive.
#
# `bun run dev` in app/ would run the predev hook (generate:app-config) and then spawn
# vite as a child, which would leave launchd supervising a wrapper rather than the
# process that holds the port. So this runs the hook itself, then `exec`s vite directly
# with the same argv `bun run dev` resolves to — the PID launchd keeps alive is the
# listener, and a respawn always finds the port free.
#
# Bootstrap: launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mwp.openbot-app.plist

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

APP_PORT="$(setting APP_PORT 3010)"

BUN="$(command -v bun || echo "$HOME/.bun/bin/bun")"

# The predev hook start.sh triggers by going through `bun run dev`.
(cd "$ROOT" && "$BUN" run generate:app-config)

cd app
exec "$BUN" --bun node_modules/vite/bin/vite.js --port "$APP_PORT" --strictPort
