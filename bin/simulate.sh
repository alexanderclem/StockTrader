#!/bin/bash
# Backtest momentum strategy. Usage: simulate.sh TICKER [-b PCT] [-l MIN] [-d MIN] [-s PCT] [-v]
# Strategy: BUY if up >= BUY_PCT in last LOOKBACK min; SELL after HOLD min or down STOP_PCT.

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
source "$ROOT/config/strategies.conf"

TICKER="${1:?Usage: $0 TICKER [-b PCT] [-l MIN] [-d MIN] [-s PCT] [-v]}"
TICKER="${TICKER^^}"
shift

VERBOSE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b) BUY_PCT="$2"; shift 2 ;;
        -l) LOOKBACK_MIN="$2"; shift 2 ;;
        -d) HOLD_MIN="$2"; shift 2 ;;
        -s) STOP_PCT="$2"; shift 2 ;;
        -v) VERBOSE=1; shift ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

CSV="$ROOT/data/${TICKER}.csv"
[[ -f "$CSV" ]] || { echo "No data file: $CSV" >&2; exit 1; }

python3 - "$CSV" "$TICKER" "$BUY_PCT" "$LOOKBACK_MIN" "$HOLD_MIN" "$STOP_PCT" "$CASH" "$SHARES" "$VERBOSE" << 'PYEOF'
import sys, csv
from datetime import datetime

path, ticker = sys.argv[1], sys.argv[2]
buy_pct, lookback, hold = float(sys.argv[3]), int(sys.argv[4])*60, int(sys.argv[5])*60
stop_pct, cash, shares = float(sys.argv[6]), float(sys.argv[7]), int(sys.argv[8])
verbose = int(sys.argv[9])
start_cash = cash

rows = [(int(r["epoch"]), float(r["price"])) for r in csv.DictReader(open(path))]
if len(rows) < 2:
    print(f"{ticker}: insufficient data ({len(rows)} rows)"); sys.exit(0)

position = None    # {"buy_epoch", "buy_price"}
trades = []

def lookback_price(i):
    target = rows[i][0] - lookback
    for j in range(i-1, -1, -1):
        if rows[j][0] <= target: return rows[j][1]
    return None

for i, (epoch, price) in enumerate(rows):
    # Exit check
    if position:
        held = epoch - position["buy_epoch"]
        pnl_pct = (price - position["buy_price"]) / position["buy_price"] * 100
        reason = "STOP" if pnl_pct <= -stop_pct else ("TIME" if held >= hold else None)
        if reason:
            pnl = (price - position["buy_price"]) * shares
            cash += price * shares
            trades.append({"pnl": pnl, "pct": pnl_pct, "reason": reason})
            if verbose:
                t = datetime.fromtimestamp(epoch).strftime("%m-%d %H:%M")
                print(f"  SELL {ticker} @ {price:7.2f} on {t} | P&L ${pnl:+7.2f} ({pnl_pct:+5.2f}%) [{reason}]")
            position = None
    # Entry check
    if not position:
        lb = lookback_price(i)
        if lb and (price - lb) / lb * 100 >= buy_pct and cash >= price * shares:
            cash -= price * shares
            position = {"buy_epoch": epoch, "buy_price": price}
            if verbose:
                t = datetime.fromtimestamp(epoch).strftime("%m-%d %H:%M")
                print(f"  BUY  {ticker} @ {price:7.2f} on {t} | trigger +{(price-lb)/lb*100:.2f}%")

# Force-close any open position at final price
if position:
    final = rows[-1][1]
    pnl = (final - position["buy_price"]) * shares
    cash += final * shares
    trades.append({"pnl": pnl, "pct": (final-position["buy_price"])/position["buy_price"]*100, "reason": "CLOSE"})

wins = [t for t in trades if t["pnl"] > 0]
total_pnl = cash - start_cash
ret = total_pnl / start_cash * 100
bh_ret = (rows[-1][1] - rows[0][1]) / rows[0][1] * 100
bh_pnl = start_cash * bh_ret / 100

print(f"\n=== {ticker} ===")
print(f"  Period:        {datetime.fromtimestamp(rows[0][0])} -> {datetime.fromtimestamp(rows[-1][0])}")
print(f"  Strategy:      +{buy_pct}% in {lookback//60}m, hold {hold//60}m, stop -{stop_pct}%")
print(f"  Trades:        {len(trades)} ({len(wins)} wins, {len(trades)-len(wins)} losses)")
if trades: print(f"  Win rate:      {len(wins)/len(trades)*100:.1f}%")
print(f"  Strategy P&L:  ${total_pnl:+,.2f} ({ret:+.2f}%)")
print(f"  Buy & hold:    ${bh_pnl:+,.2f} ({bh_ret:+.2f}%)")
print(f"  vs B&H:        {ret-bh_ret:+.2f} pp")
PYEOF
