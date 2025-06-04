#!/bin/bash

echo "🧪 Quick Honeypot Test..."

# Test SSH connection with common credentials
echo "🔐 Testing SSH honeypot..."

# Install sshpass if not available
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass for automated testing..."
    sudo apt update && sudo apt install -y sshpass
fi

# Test different credentials
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
    
    # Try to connect and execute some commands
    timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" << EOF 2>/dev/null
ls -la
cat /etc/passwd
ps aux
uname -a
whoami
id
exit
EOF
    
    sleep 2
done

echo ""
echo "📝 Recent log entries:"
if [ -f "/home/cowrie/cowrie/var/log/cowrie/cowrie.json" ]; then
    echo "Last 5 log entries:"
    tail -5 /home/cowrie/cowrie/var/log/cowrie/cowrie.json | jq . 2>/dev/null || tail -5 /home/cowrie/cowrie/var/log/cowrie/cowrie.json
else
    echo "  Log file not found"
fi

echo ""
echo "✅ Test complete! Check the dashboard at http://localhost:3000"
