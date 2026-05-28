#!/bin/bash
# Log prices to data/<TICKER>.csv every INTERVAL seconds. Reads config/tickers.conf.

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
INTERVAL="${1:-60}"

# Strip comments and blanks from tickers.conf
mapfile -t TICKERS < <(grep -vE '^\s*(#|$)' "$ROOT/config/tickers.conf")
[[ ${#TICKERS[@]} -eq 0 ]] && { echo "No tickers configured" >&2; exit 1; }

trap 'echo "monitor stopped"; exit 0' INT TERM
echo "Monitoring: ${TICKERS[*]} every ${INTERVAL}s"

while true; do
    for t in "${TICKERS[@]}"; do
        price=$("$SCRIPT_DIR/fetch.sh" "$t" 2>/dev/null) || continue
        csv="$ROOT/data/${t}.csv"
        [[ -f "$csv" ]] || echo "epoch,price" > "$csv"
        echo "$(date +%s),$price" >> "$csv"
    done
    sleep "$INTERVAL"
done
