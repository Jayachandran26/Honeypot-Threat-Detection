#!/bin/bash

echo "🧪 Testing Cowrie Honeypot..."

# Function to test SSH
test_ssh() {
    echo "🔐 Testing SSH connection..."
    
    # Test with different credentials
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
        
        echo "  Testing $username:$password"
        
        # Use sshpass to automate password entry
        if command -v sshpass >/dev/null 2>&1; then
            timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 "$username@localhost" "ls -la; cat /etc/passwd; ps aux; exit" 2>/dev/null
        else
            echo "    (Install sshpass for automated testing: sudo apt install sshpass)"
        fi
        
        sleep 2
    done
}

# Function to test Telnet
test_telnet() {
    echo "📞 Testing Telnet connection..."
    
    # Create expect script for telnet testing
    if command -v expect >/dev/null 2>&1; then
        expect << 'EOF'
spawn telnet localhost 2223
expect "login:"
send "root\r"
expect "Password:"
send "admin\r"
expect "$ "
send "ls -la\r"
expect "$ "
send "cat /etc/passwd\r"
expect "$ "
send "ps aux\r"
expect "$ "
send "exit\r"
expect eof
EOF
    else
        echo "  (Install expect for automated testing: sudo apt install expect)"
        echo "  Manual test: telnet localhost 2223"
    fi
}

# Check if Cowrie is running
if ! sudo systemctl is-active --quiet cowrie; then
    echo "❌ Cowrie is not running"
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Install testing tools if needed
echo "📦 Installing testing tools..."
sudo apt update
sudo apt install -y sshpass expect netcat-openbsd

# Run tests
test_ssh
test_telnet

# Generate some additional traffic
echo "🌐 Generating additional test traffic..."

# Test with netcat
echo "  Testing with netcat..."
echo "test connection" | nc localhost 2222 &
sleep 1

echo "test connection" | nc localhost 2223 &
sleep 1

# Show recent log entries
echo ""
echo "📝 Recent log entries:"
if [ -f "/home/cowrie/cowrie/var/log/cowrie/cowrie.json" ]; then
    tail -5 /home/cowrie/cowrie/var/log/cowrie/cowrie.json
else
    echo "  Log file not found"
fi

echo ""
echo "✅ Testing complete!"
echo "📊 Check the dashboard at http://localhost:3000 to see the results"
