#!/bin/bash
# Usage: ./switch-env.sh [codespace-name]

if [ -z "$1" ]; then
  echo "Available environments:"
  for env_file in ~/.spark-env-*; do
    if [ -f "$env_file" ] && [ "$env_file" != "$HOME/.spark-env-current" ]; then
      name=$(basename "$env_file" | sed 's/spark-env-//')
      branch=$(grep "^BRANCH=" "$env_file" 2>/dev/null | cut -d= -f2)
      echo "  $name ($branch)"
    fi
  done

  if [ -L ~/.spark-env-current ]; then
    current=$(basename $(readlink ~/.spark-env-current) | sed 's/spark-env-//')
    echo ""
    echo "Current: $current"
  fi
  exit 0
fi

ENV_FILE=~/.spark-env-$1

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment '$1' not found"
  echo "Run without arguments to list available environments"
  exit 1
fi

ln -sf "$ENV_FILE" ~/.spark-env-current
source ~/.spark-env-current

echo "Switched to: $1"
echo "  Branch: $BRANCH"
echo "  Ruby:   $RUBY_URL"
echo "  Java:   $JAVA_URL"
echo "  Metro:  $METRO_URL"
