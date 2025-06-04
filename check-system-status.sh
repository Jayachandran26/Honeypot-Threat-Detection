#!/bin/bash

echo "📊 SYSTEM STATUS CHECK"
echo "====================="

echo "🔍 Cowrie Service:"
if systemctl is-active --quiet cowrie; then
    echo "   ✅ Running"
    echo "   📊 PID: $(pgrep cowrie)"
else
    echo "   ❌ Not running"
fi

echo ""
echo "🔍 Cowrie Ports:"
echo "   SSH (2222): $(ss -ln | grep :2222 > /dev/null && echo "✅ Listening" || echo "❌ Not listening")"
echo "   Telnet (2223): $(ss -ln | grep :2223 > /dev/null && echo "✅ Listening" || echo "❌ Not listening")"

echo ""
echo "🔍 Log File:"
LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
if [ -f "$LOG_PATH" ]; then
    echo "   ✅ Exists: $LOG_PATH"
    echo "   📊 Size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "   📄 Lines: $(wc -l < "$LOG_PATH")"
    if [ -s "$LOG_PATH" ]; then
        echo "   📝 Recent activity: $(tail -1 "$LOG_PATH" | jq -r '.timestamp // "No timestamp"' 2>/dev/null || echo "Invalid JSON")"
    fi
else
    echo "   ❌ Not found: $LOG_PATH"
fi

echo ""
echo "🔍 Dashboard:"
if pgrep -f "next dev" > /dev/null; then
    echo "   ✅ Running on http://localhost:3000"
else
    echo "   ❌ Not running"
fi

echo ""
echo "🔍 Log Sync:"
if pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "   ✅ Running"
else
    echo "   ⚠️ Not running (optional)"
fi

echo ""
echo "🔍 Environment:"
if [ -f ".env.local" ]; then
    echo "   ✅ .env.local exists"
    echo "   📄 COWRIE_LOG_PATH: $(grep COWRIE_LOG_PATH .env.local | cut -d= -f2)"
else
    echo "   ❌ .env.local not found"
fi
