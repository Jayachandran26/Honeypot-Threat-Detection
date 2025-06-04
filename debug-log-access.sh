#!/bin/bash

echo "🔍 Debugging Cowrie Log Access..."

# Check if the expected log file exists
LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo "Expected log path: $LOG_PATH"

if [ -f "$LOG_PATH" ]; then
    echo "✅ Log file exists"
    echo "📊 File size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "🔒 Permissions: $(ls -la "$LOG_PATH")"
    echo "📝 Last 3 lines:"
    tail -3 "$LOG_PATH" 2>/dev/null || echo "Cannot read file content"
else
    echo "❌ Log file does not exist at expected path"
fi

# Find where Cowrie is actually logging
echo ""
echo "🔍 Finding actual Cowrie log location..."

# Check Cowrie configuration
echo "Checking Cowrie configuration..."
sudo -u cowrie bash << 'EOF'
if [ -f "$HOME/cowrie/etc/cowrie.cfg" ]; then
    echo "✅ Found Cowrie config file"
    echo "JSON log configuration:"
    grep -A 5 "\[output_jsonlog\]" "$HOME/cowrie/etc/cowrie.cfg" || echo "No JSON log config found"
else
    echo "❌ Cowrie config file not found"
fi
EOF

# Check for any JSON log files
echo ""
echo "🔍 Searching for any Cowrie JSON log files..."
sudo find /home/cowrie -name "*.json" -type f 2>/dev/null | while read file; do
    echo "Found: $file"
    echo "  Size: $(du -h "$file" | cut -f1)"
    echo "  Permissions: $(ls -la "$file")"
done

# Check Cowrie process and working directory
echo ""
echo "🔍 Checking Cowrie process details..."
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    echo "Cowrie PID: $COWRIE_PID"
    echo "Working directory:"
    sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep cwd
    echo "Open files:"
    sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep -E "\.(json|log)$"
fi

# Check systemd service logs for clues
echo ""
echo "🔍 Checking Cowrie service logs..."
echo "Recent Cowrie logs:"
sudo journalctl -u cowrie --no-pager -n 10

echo ""
echo "🔍 Debug complete!"
