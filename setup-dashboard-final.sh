#!/bin/bash

echo "🔗 Final Dashboard Setup with Cowrie..."

# Function to find Cowrie working directory
find_cowrie_working_dir() {
    # Method 1: Check systemd working directory
    WORKING_DIR=$(systemctl show cowrie -p WorkingDirectory --value 2>/dev/null)
    if [ -n "$WORKING_DIR" ] && [ -d "$WORKING_DIR" ]; then
        echo "$WORKING_DIR"
        return 0
    fi
    
    # Method 2: Check process working directory
    COWRIE_PID=$(pgrep -f cowrie | head -1)
    if [ -n "$COWRIE_PID" ]; then
        PROC_DIR=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep cwd | awk '{print $9}')
        if [ -n "$PROC_DIR" ] && [ -d "$PROC_DIR" ]; then
            echo "$PROC_DIR"
            return 0
        fi
    fi
    
    # Method 3: Check common locations with sudo
    possible_paths=(
        "/home/cowrie/cowrie"
        "/opt/cowrie"
        "/usr/local/cowrie"
    )
    
    for path in "${possible_paths[@]}"; do
        if sudo test -d "$path"; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Check if Cowrie service is running
if ! systemctl is-active --quiet cowrie; then
    echo "❌ Cowrie service is not running"
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Find Cowrie directory
echo "🔍 Finding Cowrie installation..."
COWRIE_DIR=$(find_cowrie_working_dir)

if [ -z "$COWRIE_DIR" ]; then
    echo "❌ Could not find Cowrie directory"
    echo "Let's try to access it as cowrie user..."
    
    # Try to access as cowrie user
    COWRIE_DIR=$(sudo -u cowrie bash -c 'if [ -d "$HOME/cowrie" ]; then echo "$HOME/cowrie"; fi')
    
    if [ -z "$COWRIE_DIR" ]; then
        echo "❌ Still cannot find Cowrie directory"
        echo "Please check the installation"
        exit 1
    fi
fi

echo "✅ Found Cowrie at: $COWRIE_DIR"

# Set up log file path
LOG_DIR="$COWRIE_DIR/var/log/cowrie"
LOG_FILE="$LOG_DIR/cowrie.json"

echo "🔧 Setting up log directory..."
sudo -u cowrie mkdir -p "$LOG_DIR"
sudo -u cowrie touch "$LOG_FILE"

# Make sure the log file is readable
sudo chmod 644 "$LOG_FILE"

echo "✅ Log file ready: $LOG_FILE"

# Configure environment
echo "🔧 Configuring environment..."
cat > .env.local << EOF
COWRIE_LOG_PATH=$LOG_FILE
EOF

echo "✅ Environment configured"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Test log file access
echo "🧪 Testing log file access..."
if [ -r "$LOG_FILE" ]; then
    echo "✅ Log file is readable"
    echo "📊 Current size: $(du -h "$LOG_FILE" | cut -f1)"
else
    echo "❌ Cannot read log file, fixing permissions..."
    sudo chmod 644 "$LOG_FILE"
fi

# Check ports
echo "🔍 Checking ports..."
if ss -ln | grep -q ":2222"; then
    echo "✅ SSH honeypot (port 2222) is active"
else
    echo "❌ SSH honeypot (port 2222) is not listening"
fi

if ss -ln | grep -q ":2223"; then
    echo "✅ Telnet honeypot (port 2223) is active"
else
    echo "❌ Telnet honeypot (port 2223) is not listening"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 Starting dashboard..."

# Kill any existing dev server
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start the dashboard
npm run dev &
DEV_PID=$!

sleep 5

echo ""
echo "🎯 Your honeypot is ready! Test it with:"
echo ""
echo "SSH Tests:"
echo "  ssh root@localhost -p 2222"
echo "  ssh admin@localhost -p 2222"
echo ""
echo "Telnet Test:"
echo "  telnet localhost 2223"
echo ""
echo "🔑 Common credentials to try:"
echo "  root/admin, admin/password, user/123456"
echo ""
echo "📊 Dashboard: http://localhost:3000"
echo "📝 Live logs: sudo tail -f $LOG_FILE"
echo ""
echo "🛑 To stop dashboard: kill $DEV_PID"
