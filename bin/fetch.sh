#!/bin/bash
# Fetch current price for one ticker from Yahoo Finance. Usage: fetch.sh AAPL

set -u
TICKER="${1:?Usage: $0 TICKER}"
TICKER="${TICKER^^}"

URL="https://query1.finance.yahoo.com/v8/finance/chart/${TICKER}?interval=1m&range=1d"
RESPONSE=$(curl -s -f --max-time 10 -A "Mozilla/5.0" "$URL") || { echo "ERROR: fetch failed" >&2; exit 1; }

echo "$RESPONSE" | python3 -c 'import sys, json
d = json.load(sys.stdin)
p = d["chart"]["result"][0]["meta"]["regularMarketPrice"]
print(f"{p:.4f}")'
