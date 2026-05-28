#!/bin/bash
# Live refreshing dashboard. Usage: dashboard.sh [INTERVAL_SEC]

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERVAL="${1:-10}"
trap 'exit 0' INT TERM

while true; do
    clear
    echo "STOCK DASHBOARD  $(date '+%Y-%m-%d %H:%M:%S')  (refresh ${INTERVAL}s, Ctrl-C to exit)"
    echo "------------------------------------------------------------------------"
    "$SCRIPT_DIR/report.sh"
    sleep "$INTERVAL"
done
