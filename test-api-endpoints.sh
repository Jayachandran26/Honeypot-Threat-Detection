#!/bin/bash

echo "🧪 Testing API Endpoints..."

# Check if development server is running
if ! pgrep -f "next dev" > /dev/null; then
    echo "🚀 Starting development server..."
    npm run dev &
    sleep 10
fi

echo "🔍 Testing API endpoints..."

echo ""
echo "1. Testing /api/cowrie/status"
echo "================================"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/cowrie/status

echo ""
echo "2. Testing /api/cowrie/events"
echo "================================"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/cowrie/events

echo ""
echo "3. Testing /api/cowrie/stats"
echo "================================"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/cowrie/stats

echo ""
echo "4. Checking log file directly"
echo "================================"
LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
if [ -f "$LOG_PATH" ]; then
    echo "✅ Log file exists: $LOG_PATH"
    echo "📊 Size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "🔒 Permissions: $(ls -la "$LOG_PATH")"
    echo "📄 Line count: $(wc -l < "$LOG_PATH")"
    if [ -s "$LOG_PATH" ]; then
        echo "📝 Last 3 lines:"
        tail -3 "$LOG_PATH"
    else
        echo "📝 File is empty"
    fi
else
    echo "❌ Log file not found: $LOG_PATH"
fi

echo ""
echo "✅ API testing complete!"
