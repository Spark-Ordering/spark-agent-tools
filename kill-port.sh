#!/bin/bash
# Kill process(es) listening on a given port
#
# Usage: ./kill-port.sh <port> [port2] [port3] ...
#        ./kill-port.sh 8081
#        ./kill-port.sh 8081 54321

if [ $# -eq 0 ]; then
  echo "Usage: kill-port.sh <port> [port2] ..."
  exit 1
fi

for PORT in "$@"; do
  PIDS=$(/usr/sbin/lsof -ti:"$PORT" 2>/dev/null)
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill -9
    echo "✓ Killed port $PORT (PIDs: $(echo $PIDS | tr '\n' ' '))"
  else
    echo "· Port $PORT: nothing listening"
  fi
done
