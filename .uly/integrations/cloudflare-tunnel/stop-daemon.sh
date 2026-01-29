#!/bin/bash
# Arrête le daemon ULY (serveur + tunnel)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.daemon.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "not running"
    exit 0
fi

SERVER_PID=$(sed -n '1p' "$PID_FILE")
TUNNEL_PID=$(sed -n '2p' "$PID_FILE")

kill $SERVER_PID 2>/dev/null
kill $TUNNEL_PID 2>/dev/null

rm -f "$PID_FILE"

echo "stopped"
exit 0
