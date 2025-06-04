#!/bin/bash

echo "🧪 Testing Dual Log System"
echo "=========================="

PRIMARY_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
SECONDARY_LOG="$(pwd)/cowrie-logs/cowrie.json"

echo ""
echo "📊 System Status Check:"
echo "======================"

# Check if Cowrie is running
if pgrep cowrie > /dev/null; then
    echo "✅ Cowrie is running"
else
    echo "❌ Cowrie is not running"
fi

# Check log files
echo ""
echo "📄 Log File Status:"
if [ -f "$PRIMARY_LOG" ]; then
    PRIMARY_SIZE=$(sudo wc -l < "$PRIMARY_LOG" 2>/dev/null || echo "0")
    echo "✅ Primary log exists: $PRIMARY_SIZE lines"
else
    echo "❌ Primary log not found: $PRIMARY_LOG"
fi

if [ -f "$SECONDARY_LOG" ]; then
    SECONDARY_SIZE=$(wc -l < "$SECONDARY_LOG" 2>/dev/null || echo "0")
    echo "✅ Secondary log exists: $SECONDARY_SIZE lines"
else
    echo "❌ Secondary log not found: $SECONDARY_LOG"
fi

# Check sync process
echo ""
echo "🔄 Sync Process Status:"
if pgrep -f "sync-dual-logs.sh" > /dev/null; then
    SYNC_PID=$(pgrep -f "sync-dual-logs.sh")
    echo "✅ Sync process running (PID: $SYNC_PID)"
else
    echo "❌ Sync process not running"
    echo "💡 Start it with: ./sync-dual-logs.sh &"
fi

# Test dashboard API
echo ""
echo "🌐 Testing Dashboard API:"
if curl -s http://localhost:3000/api/cowrie/events > /dev/null; then
    echo "✅ Dashboard API responding"
else
    echo "❌ Dashboard API not responding"
    echo "💡 Make sure to run: npm run dev"
fi

# Test email alert API
echo ""
echo "📧 Testing Email Alert API:"
if curl -s http://localhost:3000/api/alerts/monitor > /dev/null; then
    echo "✅ Email alert API responding"
else
    echo "❌ Email alert API not responding"
fi

# Generate a test attack
echo ""
echo "🎯 Generating Test Attack:"
echo "========================="
echo "Attempting SSH connection to trigger alerts..."

# Use timeout to prevent hanging
timeout 10s ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost -p 2222 << 'EOF' 2>/dev/null || true
admin
exit
EOF

echo "✅ Test attack generated"

# Wait for logs to update
echo ""
echo "⏳ Waiting for logs to update..."
sleep 5

# Check if new entries were added
echo ""
echo "📈 Log Update Check:"
if [ -f "$SECONDARY_LOG" ]; then
    NEW_SECONDARY_SIZE=$(wc -l < "$SECONDARY_LOG" 2>/dev/null || echo "0")
    if [ "$NEW_SECONDARY_SIZE" -gt "$SECONDARY_SIZE" ]; then
        echo "✅ Secondary log updated: $NEW_SECONDARY_SIZE lines (+$((NEW_SECONDARY_SIZE - SECONDARY_SIZE)))"
    else
        echo "⚠️ Secondary log not updated"
    fi
fi

echo ""
echo "🎯 TEST COMPLETE!"
echo "================"
echo "📊 Dashboard: http://localhost:3000"
echo "📧 Alerts: http://localhost:3000/alerts"
echo "🔍 Monitor logs: tail -f $SECONDARY_LOG"
