#!/bin/bash

echo "🔍 Diagnosing Cowrie Installation..."

# Check if cowrie user exists
echo "👤 Checking cowrie user:"
if id "cowrie" &>/dev/null; then
    echo "✅ User 'cowrie' exists"
    echo "   Home directory: $(getent passwd cowrie | cut -d: -f6)"
else
    echo "❌ User 'cowrie' does not exist"
fi

# Check possible Cowrie directories
echo ""
echo "📁 Checking for Cowrie directories:"
possible_paths=(
    "/home/cowrie/cowrie"
    "/opt/cowrie"
    "/usr/local/cowrie"
    "/var/lib/cowrie"
)

for path in "${possible_paths[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ Found: $path"
        ls -la "$path" | head -5
    else
        echo "❌ Not found: $path"
    fi
done

# Check if Cowrie service is running
echo ""
echo "🔧 Checking Cowrie service:"
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie service is running"
    systemctl status cowrie --no-pager -l | head -10
else
    echo "❌ Cowrie service is not running"
fi

# Check for Cowrie processes
echo ""
echo "🔍 Checking for Cowrie processes:"
if pgrep -f "cowrie" > /dev/null; then
    echo "✅ Cowrie processes found:"
    ps aux | grep cowrie | grep -v grep
else
    echo "❌ No Cowrie processes found"
fi

# Check ports
echo ""
echo "🌐 Checking ports:"
if netstat -ln 2>/dev/null | grep -q ":2222"; then
    echo "✅ Port 2222 is listening"
else
    echo "❌ Port 2222 is not listening"
fi

if netstat -ln 2>/dev/null | grep -q ":2223"; then
    echo "✅ Port 2223 is listening"
else
    echo "❌ Port 2223 is not listening"
fi

# Check for log files
echo ""
echo "📝 Checking for log files:"
possible_logs=(
    "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
    "/opt/cowrie/var/log/cowrie/cowrie.json"
    "/var/log/cowrie/cowrie.json"
)

for log in "${possible_logs[@]}"; do
    if [ -f "$log" ]; then
        echo "✅ Found log: $log"
        echo "   Size: $(du -h "$log" | cut -f1)"
        echo "   Permissions: $(ls -la "$log")"
    else
        echo "❌ Not found: $log"
    fi
done

echo ""
echo "🔍 Diagnosis complete!"
