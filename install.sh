#!/bin/bash
# Install deps and launch tmux session with monitor + dashboard.

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

command -v apt-get >/dev/null && sudo apt-get install -y -qq curl python3 tmux
chmod +x "$ROOT"/bin/*.sh "$ROOT"/install.sh

"$ROOT/bin/fetch.sh" AAPL >/dev/null || { echo "Smoke test failed"; exit 1; }

tmux kill-session -t stocks 2>/dev/null || true
tmux new-session -d -s stocks "cd $ROOT && bin/monitor.sh 60"
tmux split-window -t stocks "cd $ROOT && sleep 5 && bin/dashboard.sh 15"
tmux split-window -t stocks "cd $ROOT && exec bash"
tmux select-layout -t stocks tiled

echo "Running. Attach: tmux attach -t stocks. Stop: tmux kill-session -t stocks"
