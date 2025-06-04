#!/bin/bash

echo "🍯 Setting up Real Cowrie Integration..."

# Check if Cowrie is installed
if [ ! -d "/home/cowrie/cowrie" ]; then
    echo "❌ Cowrie not found at /home/cowrie/cowrie"
    echo "Please install Cowrie first using the setup scripts provided earlier."
    exit 1
fi

# Check if Cowrie is running
if ! pgrep -f "cowrie" > /dev/null; then
    echo "⚠️  Cowrie is not running. Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Check if log file exists
COWRIE_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
if [ ! -f "$COWRIE_LOG" ]; then
    echo "📝 Creating Cowrie log file..."
    sudo touch "$COWRIE_LOG"
    sudo chown cowrie:cowrie "$COWRIE_LOG"
fi

# Set up environment variable
echo "🔧 Configuring environment..."
echo "COWRIE_LOG_PATH=$COWRIE_LOG" > .env.local

# Check ports
echo "🔍 Checking Cowrie ports..."
if netstat -ln | grep -q ":2222"; then
    echo "✅ SSH honeypot is listening on port 2222"
else
    echo "❌ SSH honeypot is not listening on port 2222"
fi

if netstat -ln | grep -q ":2223"; then
    echo "✅ Telnet honeypot is listening on port 2223"
else
    echo "❌ Telnet honeypot is not listening on port 2223"
fi

# Start the dashboard
echo "🚀 Starting the dashboard..."
npm run dev &

echo ""
echo "✅ Setup complete!"
echo ""
echo "🔗 Dashboard: http://localhost:3000"
echo "🎯 SSH Honeypot: ssh root@localhost -p 2222"
echo "🎯 Telnet Honeypot: telnet localhost 2223"
echo ""
echo "💡 To generate attack data, try connecting with different credentials:"
echo "   ssh admin@localhost -p 2222"
echo "   ssh user@localhost -p 2222"
echo "   ssh guest@localhost -p 2222"
echo ""
echo "🔑 Try common passwords: admin, password, 123456, root, test"
echo ""
echo "📊 The dashboard will update automatically as attacks are detected!"
