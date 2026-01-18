#!/bin/bash

echo "Starting Spark services..."

# Start spark_backend (Rails)
cd spark_backend && rails server -p 3000 &
RAILS_PID=$!

# Start RequestManager (Java)
cd RequestManager && java -jar target/*.jar --server.port=8080 &
JAVA_PID=$!

# Start sparkpos Metro bundler
cd sparkpos && npm start -- --port 8081 &
METRO_PID=$!

echo ""
echo "=== Services starting... ==="
echo "  Ruby:  http://localhost:3000"
echo "  Java:  http://localhost:8080"
echo "  Metro: http://localhost:8081"
echo ""
echo "PIDs: Rails=$RAILS_PID, Java=$JAVA_PID, Metro=$METRO_PID"
echo "Press Ctrl+C to stop all services"

# Wait for any process to exit
wait
