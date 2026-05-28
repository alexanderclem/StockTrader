# Stock Monitor & Trading Simulator

Bash project for monitoring stock prices and testing stock-trading strategy.

## Layout

```
bin/
  fetch.sh       fetch one current price from Yahoo Finance
  monitor.sh     loop and log prices to data/<TICKER>.csv
  simulate.sh    backtest momentum strategy with buy-and-hold benchmark
  report.sh      per-ticker stats
  dashboard.sh   refreshing terminal view (wraps report.sh)
config/
  tickers.conf       one symbol per line
  strategies.conf    BUY_PCT, LOOKBACK_MIN, HOLD_MIN, STOP_PCT, CASH, SHARES
install.sh       apt deps + launches tmux session "stocks"
```

## Run

```bash
chmod +x bin/*.sh install.sh
./install.sh                          # full setup + tmux
tmux attach -t stocks                 # see it live
```

Manual use:

```bash
bin/fetch.sh AAPL                     # 311.17
bin/monitor.sh 30                     # log every 30 sec (Ctrl-C to stop)
bin/report.sh                         # all tickers, one line each
bin/simulate.sh AAPL -v               # backtest with config defaults
bin/simulate.sh AAPL -b 0.3 -l 10 -v  # override threshold + lookback
```

## Strategy

BUY when price has risen `BUY_PCT`% in the last `LOOKBACK_MIN` minutes.
SELL after `HOLD_MIN` minutes OR when down `STOP_PCT`% from buy (whichever first).
One open position per ticker. Each ticker is simulated independently
with its own $`CASH` starting balance.

Output includes win rate, total P&L, and a buy-and-hold benchmark for
the same period.

## Design

Bash handles orchestration (loops, args, files, tmux). Python3 (preinstalled
on Debian) handles JSON parsing and floating-point math via inline `python3 -c`.
This is intentional — bash floats need `bc`, and JSON-by-regex is brittle.
