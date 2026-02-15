#!/bin/bash
# Check for launchApp in Maestro YAML files - this breaks Metro!

FOUND=0
for dir in /Users/carlos/Code/SparkPos /Users/carlos/Code/SparkPos2 /Users/carlos/Code/SparkPos3; do
  if [ -d "$dir/.maestro" ]; then
    MATCHES=$(grep -l "launchApp" "$dir"/.maestro/*.yaml 2>/dev/null)
    if [ -n "$MATCHES" ]; then
      echo "⚠️ FOUND launchApp in:"
      echo "$MATCHES"
      FOUND=1
    fi
  fi
done

if [ $FOUND -eq 1 ]; then
  echo ""
  echo "launchApp breaks Metro! Remove it from YAML files."
  echo "App should be pre-launched by e2e.sh script."
  exit 1
fi

exit 0
