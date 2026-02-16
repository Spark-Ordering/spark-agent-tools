#!/bin/bash
# Run SparkPos emulator with clean state
# Wrapper for npm run eiu in the SparkPos directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"

SPARKPOS_DIR=$(find_repo "SparkPos.git")

cd "$SPARKPOS_DIR"
npm run eiu
