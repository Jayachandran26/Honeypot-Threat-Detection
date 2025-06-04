#!/bin/bash

echo "📋 Current Cowrie Configuration"
echo "==============================="

echo ""
echo "🔍 Environment Variables:"
echo "-------------------------"
if [ -f ".env.local" ]; then
    echo "✅ .env.local file exists"
    echo "Contents:"
    cat .env.local
else
    echo "❌ No .env.local file found"
fi

echo ""
echo "🌍 System Environment:"
echo "----------------------"
echo "COWRIE_LOG_PATH: ${COWRIE_LOG_PATH:-'Not set'}"
echo "USER: $USER"
echo "HOME: $HOME"
echo "PWD: $(pwd)"

echo ""
echo "🔍 Cowrie Process Information:"
echo "-----------------------------"
if pgrep -f cowrie > /dev/null; then
    echo "✅ Cowrie is running"
    echo "Process details:"
    ps aux | grep cowrie | grep -v grep
    
    echo ""
    echo "Process working directories:"
    for pid in $(pgrep -f cowrie); do
        if [ -r "/proc/$pid/cwd" ]; then
            echo "  PID $pid: $(readlink /proc/$pid/cwd 2>/dev/null || echo 'Cannot read')"
        fi
    done
else
    echo "❌ Cowrie is not running"
fi

echo ""
echo "🔍 Systemd Service Status:"
echo "--------------------------"
if systemctl list-unit-files | grep -q cowrie; then
    echo "✅ Cowrie service exists"
    systemctl status cowrie --no-pager -l
else
    echo "❌ No Cowrie systemd service found"
fi

echo ""
echo "📁 Log File Status:"
echo "------------------"
LOG_PATHS=(
    "${COWRIE_LOG_PATH}"
    "./cowrie-logs/cowrie.json"
    "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
    "/home/$USER/cowrie/var/log/cowrie/cowrie.json"
    "/opt/cowrie/var/log/cowrie/cowrie.json"
)

for path in "${LOG_PATHS[@]}"; do
    if [ -n "$path" ] && [ -f "$path" ]; then
        echo "✅ Found log file: $path"
        echo "   Size: $(du -h "$path" | cut -f1)"
        echo "   Permissions: $(ls -la "$path")"
        echo "   Last modified: $(stat -c %y "$path" 2>/dev/null || stat -f %Sm "$path" 2>/dev/null)"
        
        # Check if readable
        if [ -r "$path" ]; then
            echo "   ✅ File is readable"
            LINES=$(wc -l < "$path" 2>/dev/null || echo "0")
            echo "   Lines: $LINES"
        else
            echo "   ❌ File is not readable"
        fi
    elif [ -n "$path" ]; then
        echo "❌ Log file not found: $path"
    fi
done

echo ""
echo "🌐 Network Status:"
echo "-----------------"
echo "Listening ports:"
if ss -ln | grep -q ":2222"; then
    echo "✅ SSH port 2222 is listening"
else
    echo "❌ SSH port 2222 is not listening"
fi

if ss -ln | grep -q ":2223"; then
    echo "✅ Telnet port 2223 is listening"
else
    echo "❌ Telnet port 2223 is not listening"
fi

echo ""
echo "📊 Recent Log Activity:"
echo "----------------------"
for path in "${LOG_PATHS[@]}"; do
    if [ -n "$path" ] && [ -f "$path" ] && [ -r "$path" ]; then
        echo "Recent entries from $path:"
        tail -3 "$path" 2>/dev/null | head -3
        break
    fi
done
