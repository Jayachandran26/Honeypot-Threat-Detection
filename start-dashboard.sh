#!/bin/bash

echo "🚀 Starting Cowrie Dashboard..."

# Check if log sync is running
if ! pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "🔄 Starting log sync process..."
    ./sync-cowrie-logs.sh &
    echo "Log sync started with PID: $!"
fi

# Check if Cowrie is running
if ! systemctl is-active --quiet cowrie; then
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Kill any existing dev server
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start the dashboard
echo "📊 Starting dashboard..."
npm run dev &
DEV_PID=$!

sleep 5

echo ""
echo "✅ Dashboard started!"
echo "📊 Dashboard: http://localhost:3000"
echo "📝 Log file: $(pwd)/cowrie-logs/cowrie.json"
echo "🎯 Test honeypot: ssh root@localhost -p 2222"
echo ""
echo "🛑 To stop:"
echo "  Dashboard: kill $DEV_PID"
echo "  Log sync: pkill -f sync-cowrie-logs.sh"
