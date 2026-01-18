#!/bin/bash
# Usage: ./teardown-env.sh [codespace-name]

if [ -z "$1" ]; then
  if [ -L ~/.spark-env-current ]; then
    CODESPACE=$(grep "^CODESPACE_NAME=" ~/.spark-env-current 2>/dev/null | cut -d= -f2)
  fi

  if [ -z "$CODESPACE" ]; then
    echo "Usage: ./teardown-env.sh <codespace-name>"
    echo "Or switch to an environment first with ./switch-env.sh"
    exit 1
  fi

  echo "No codespace specified, using current: $CODESPACE"
else
  CODESPACE=$1
fi

echo "Deleting Codespace: $CODESPACE"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  gh codespace delete -c $CODESPACE -f
  rm -f ~/.spark-env-$CODESPACE

  # If this was the current environment, remove the symlink
  if [ -L ~/.spark-env-current ]; then
    current=$(basename $(readlink ~/.spark-env-current) | sed 's/spark-env-//')
    if [ "$current" = "$CODESPACE" ]; then
      rm -f ~/.spark-env-current
    fi
  fi

  echo "Deleted: $CODESPACE"
else
  echo "Cancelled"
fi
