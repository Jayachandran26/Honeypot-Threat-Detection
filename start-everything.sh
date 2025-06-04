#!/bin/bash

echo "🚀 STARTING COMPLETE COWRIE HONEYPOT SYSTEM"
echo "=========================================="

# Step 1: Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Not in the correct project directory"
    echo "Please navigate to your Honeypot-Project/app directory first"
    exit 1
fi

echo "✅ In correct project directory"

# Step 2: Check if Cowrie is running
echo ""
echo "🔍 Step 1: Checking Cowrie Status..."
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is already running"
else
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
    
    if systemctl is-active --quiet cowrie; then
        echo "✅ Cowrie started successfully"
    else
        echo "❌ Failed to start Cowrie"
        echo "📝 Checking Cowrie logs..."
        sudo journalctl -u cowrie --no-pager -n 10
        exit 1
    fi
fi

# Step 3: Check Cowrie ports
echo ""
echo "🔍 Step 2: Checking Cowrie Ports..."
SSH_PORT=$(ss -ln | grep :2222 | wc -l)
TELNET_PORT=$(ss -ln | grep :2223 | wc -l)

if [ $SSH_PORT -gt 0 ]; then
    echo "✅ SSH honeypot listening on port 2222"
else
    echo "⚠️ SSH honeypot not listening on port 2222"
fi

if [ $TELNET_PORT -gt 0 ]; then
    echo "✅ Telnet honeypot listening on port 2223"
else
    echo "⚠️ Telnet honeypot not listening on port 2223"
fi

# Step 4: Check log file
echo ""
echo "🔍 Step 3: Checking Log File..."
LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

if [ -f "$LOG_PATH" ]; then
    echo "✅ Cowrie log file exists: $LOG_PATH"
    echo "📊 File size: $(du -h "$LOG_PATH" | cut -f1)"
    echo "📄 Lines: $(wc -l < "$LOG_PATH")"
else
    echo "⚠️ Cowrie log file not found at: $LOG_PATH"
    echo "Creating log file..."
    sudo touch "$LOG_PATH"
    sudo chmod 644 "$LOG_PATH"
fi

# Step 5: Update environment variables
echo ""
echo "🔍 Step 4: Setting Environment Variables..."
echo "COWRIE_LOG_PATH=$LOG_PATH" > .env.local
echo "✅ Environment variables updated"

# Step 6: Start log sync if needed
echo ""
echo "🔍 Step 5: Starting Log Sync..."
if pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "✅ Log sync already running"
else
    if [ -f "sync-cowrie-logs.sh" ]; then
        echo "🔄 Starting log sync..."
        ./sync-cowrie-logs.sh &
        echo "✅ Log sync started"
    else
        echo "⚠️ Log sync script not found (this is optional)"
    fi
fi

# Step 7: Install dependencies if needed
echo ""
echo "🔍 Step 6: Checking Dependencies..."
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Step 8: Kill any existing dev server
echo ""
echo "🔍 Step 7: Preparing Dashboard..."
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Step 9: Start the dashboard
echo ""
echo "🚀 Step 8: Starting Dashboard..."
echo "📊 Dashboard will be available at: http://localhost:3000"
echo "📧 Email alerts page: http://localhost:3000/alerts"
echo ""
echo "🎯 HONEYPOT ENDPOINTS:"
echo "   🔐 SSH: ssh root@localhost -p 2222"
echo "   📞 Telnet: telnet localhost 2223"
echo ""
echo "🔑 TEST CREDENTIALS:"
echo "   root:admin"
echo "   admin:password"
echo "   user:123456"
echo ""
echo "Starting dashboard in 3 seconds..."
sleep 3

npm run dev
