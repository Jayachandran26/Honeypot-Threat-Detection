#!/bin/bash

echo "🧪 Testing and Verifying Cowrie Setup..."

# Wait for Cowrie to be ready
sleep 5

# Test SSH connection
echo "🔐 Testing SSH connection..."
timeout 10 sshpass -p "admin" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost << 'EOF' 2>/dev/null
whoami
ls -la
cat /etc/passwd
ps aux
exit
EOF

# Wait for log to be written
sleep 3

# Check log file
LOG_FILE="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "📝 Checking log file..."
if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists: $LOG_FILE"
    echo "📊 Size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "📄 Lines: $(wc -l < "$LOG_FILE")"
    echo "🔒 Permissions: $(ls -la "$LOG_FILE")"
    
    if [ -s "$LOG_FILE" ]; then
        echo "📝 Recent log entries:"
        tail -3 "$LOG_FILE" | jq . 2>/dev/null || tail -3 "$LOG_FILE"
    else
        echo "📝 Log file is empty"
    fi
else
    echo "❌ Log file not found!"
fi

# Test API
echo ""
echo "🧪 Testing API..."
if pgrep -f "next dev" > /dev/null; then
    echo "Testing events API..."
    curl -s http://localhost:3000/api/cowrie/events | jq .success 2>/dev/null || echo "API test failed"
else
    echo "⚠️ Development server not running"
    echo "Start it with: npm run dev"
fi

echo ""
echo "✅ Test complete!"
