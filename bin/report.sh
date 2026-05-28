#!/bin/bash
# Print stats for one ticker or all. Usage: report.sh [TICKER]

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ $# -ge 1 ]]; then
    FILES=("$ROOT/data/${1^^}.csv")
else
    FILES=("$ROOT"/data/*.csv)
fi

for csv in "${FILES[@]}"; do
    [[ -f "$csv" ]] || continue
    python3 - "$csv" << 'PYEOF'
import sys, csv, statistics, os
path = sys.argv[1]
ticker = os.path.basename(path).replace(".csv", "")
prices = [float(r["price"]) for r in csv.DictReader(open(path))]
if not prices:
    print(f"{ticker}: no data"); sys.exit(0)
cur, start = prices[-1], prices[0]
pct = (cur - start) / start * 100 if start else 0
sd = statistics.stdev(prices) if len(prices) > 1 else 0
arrow = "▲" if pct >= 0 else "▼"
print(f"{ticker:6} n={len(prices):4} cur={cur:8.2f} {arrow}{pct:+6.2f}% "
      f"min={min(prices):7.2f} max={max(prices):7.2f} mean={statistics.mean(prices):7.2f} sd={sd:.2f}")
PYEOF
done
