#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${OPENCODE_COMPOSE_FILE:-$SCRIPT_DIR/../docker-compose.yml}"
COMPOSE_DIR="$(cd "$(dirname "$COMPOSE_FILE")" && pwd)"

# Start Ollama proxy if not already running (Docker Desktop can't reach LAN)
OLLAMA_HOST="${OLLAMA_HOST:-192.168.1.69:11434}"
OLLAMA_PROXY_PORT="${OLLAMA_PROXY_PORT:-11435}"
if ! lsof -iTCP:"$OLLAMA_PROXY_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
  "$SCRIPT_DIR/ollama-proxy.py" "$OLLAMA_HOST" "$OLLAMA_PROXY_PORT" &
  PROXY_PID=$!
  sleep 0.3
fi

vanilla_args=""
oc_args=""
for arg in "$@"; do
  if [ "$arg" = "--vanilla" ]; then
    # Generate vanilla config by stripping the plugin key from the main config
    VANILLA_TMP="$(mktemp)"
    python3 -c "
import json, sys
with open('$COMPOSE_DIR/data/config/opencode.json') as f:
    cfg = json.load(f)
cfg.pop('plugin', None)
json.dump(cfg, sys.stdout, indent=2)
" > "$VANILLA_TMP"
    VANILLA_EMPTY="$(mktemp)"
    echo '{}' > "$VANILLA_EMPTY"
    vanilla_args="-v $VANILLA_TMP:/root/.config/opencode/opencode.json:ro -v $VANILLA_EMPTY:/root/.config/opencode/oh-my-openagent.json:ro"
  else
    oc_args="$oc_args $arg"
  fi
done

docker compose -f "$COMPOSE_FILE" run --rm $vanilla_args opencode $oc_args
STATUS=$?

# Clean up
if [ -n "${VANILLA_TMP:-}" ]; then
  rm -f "$VANILLA_TMP" "${VANILLA_EMPTY:-}"
fi
if [ -n "${PROXY_PID:-}" ]; then
  kill "$PROXY_PID" 2>/dev/null
fi

exit $STATUS
