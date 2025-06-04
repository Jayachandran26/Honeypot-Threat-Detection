#!/bin/bash

echo "🎯 Quick Attack Test..."

# Install sshpass if needed
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass..."
    sudo apt update && sudo apt install -y sshpass
fi

# Test SSH attacks
echo "🔐 Testing SSH attacks..."
credentials=(
    "root:admin"
    "admin:password"
    "user:123456"
)

for cred in "${credentials[@]}"; do
    username=$(echo $cred | cut -d: -f1)
    password=$(echo $cred | cut -d: -f2)
    
    echo "  🔑 Testing $username:$password"
    
    timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" << EOF 2>/dev/null
whoami
ls -la
cat /etc/passwd
ps aux
exit
EOF
    
    sleep 2
done

# Wait for logs
sleep 5

# Check log file
LOG_PATH=$(grep COWRIE_LOG_PATH .env.local | cut -d= -f2)
echo ""
echo "📝 Checking log file: $LOG_PATH"
if [ -f "$LOG_PATH" ]; then
    echo "✅ Log file exists"
    echo "📊 Size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "📄 Lines: $(wc -l < "$LOG_PATH")"
    
    if [ -s "$LOG_PATH" ]; then
        echo "📝 Recent entries:"
        tail -3 "$LOG_PATH" | jq . 2>/dev/null || tail -3 "$LOG_PATH"
    else
        echo "📝 Log file is empty"
    fi
else
    echo "❌ Log file not found"
fi

echo ""
echo "✅ Test complete!"
