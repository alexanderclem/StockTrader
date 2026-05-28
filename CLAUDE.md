# Project context

College bash class final project. 300-pt rubric: 210 functionality, 60 presentation, 30 code.

## Class toolset
- bash, vim, tmux, curl, grep/sed/cut, bc/awk, python3 (inline only)
- Avoid: jq, perl, Node, advanced awk scripts

## Architecture
- `bin/fetch.sh` — single price (foundation)
- `bin/monitor.sh` — log loop (60-pt rubric)
- `bin/simulate.sh` — backtest with B&H benchmark (120-pt rubric)
- `bin/report.sh` + `dashboard.sh` — bonus
- `install.sh` — tmux setup (30-pt cloud deploy rubric)

## CSV format
`epoch,price` — integer seconds since 1970, simpler simulator math than ISO timestamps.

## Strategy
BUY if up >= BUY_PCT in LOOKBACK_MIN; SELL after HOLD_MIN or down STOP_PCT.
Per-ticker independent sim with $CASH each.

## Known traps
- Yahoo needs User-Agent header
- Python f-strings cannot contain backslashes — use multiline form for dict access
- `shift 2` in arg-parse will eat positional args — pop ticker first
