#!/bin/bash
# Clear Metro cache and kill existing processes

echo "Killing Metro bundler processes..."
pkill -9 -f "react-native.*start" 2>/dev/null || true
pkill -9 -f "metro" 2>/dev/null || true
lsof -ti:8081 | xargs kill -9 2>/dev/null || true

echo "Clearing Metro caches..."
rm -rf $TMPDIR/metro-* $TMPDIR/haste-* 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true

echo "Caches cleared successfully"
