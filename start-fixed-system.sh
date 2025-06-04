#!/bin/bash

echo "🚀 Starting Complete Honeypot System (Fixed Version)..."
echo "==================================================="

# Fix tailwindcss-animate issue first
echo "🔧 Fixing tailwindcss-animate issue..."
chmod +x fix-tailwind-animate.sh
./fix-tailwind-animate.sh

# Check if Cowrie is running
echo "🔍 Checking if Cowrie is running..."
if sudo systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is already running"
else
    echo "🔄 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 2
    
    if sudo systemctl is-active --quiet cowrie; then
        echo "✅ Cowrie started successfully"
    else
        echo "❌ Failed to start Cowrie. Starting manually..."
        cd /home/cowrie/cowrie
        ./bin/cowrie start
    fi
fi

# Set correct environment variables
echo "🔧 Setting environment variables..."
if [ -f .env.local ]; then
    # Update existing file
    sed -i 's|COWRIE_LOG_PATH=.*|COWRIE_LOG_PATH=/home/cowrie/cowrie/var/log/cowrie/cowrie.json|' .env.local
else
    # Create new file
    echo "COWRIE_LOG_PATH=/home/cowrie/cowrie/var/log/cowrie/cowrie.json" > .env.local
fi

# Ensure log directory exists
echo "📁 Ensuring log directory exists..."
mkdir -p cowrie-logs

# Set up log synchronization
echo "🔄 Setting up log synchronization..."
LOG_SYNC_SCRIPT="sync-cowrie-logs.sh"

# Create log sync script if it doesn't exist
if [ ! -f "$LOG_SYNC_SCRIPT" ]; then
    cat > "$LOG_SYNC_SCRIPT" << 'EOF'
#!/bin/bash
SOURCE_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
DEST_LOG="./cowrie-logs/cowrie.json"

# Create destination directory if it doesn't exist
mkdir -p $(dirname "$DEST_LOG")

# Create empty destination file if it doesn't exist
if [ ! -f "$DEST_LOG" ]; then
    touch "$DEST_LOG"
fi

echo "Starting log synchronization from $SOURCE_LOG to $DEST_LOG"
while true; do
    if [ -f "$SOURCE_LOG" ]; then
        cp "$SOURCE_LOG" "$DEST_LOG"
        echo "$(date): Log synchronized"
    else
        echo "$(date): Source log not found"
    fi
    sleep 5
done
EOF
    chmod +x "$LOG_SYNC_SCRIPT"
fi

# Check if log sync is already running
if pgrep -f "$LOG_SYNC_SCRIPT" > /dev/null; then
    echo "✅ Log synchronization is already running"
else
    echo "🔄 Starting log synchronization..."
    ./$LOG_SYNC_SCRIPT &
    echo "✅ Log synchronization started"
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Start the dashboard
echo "🚀 Starting the dashboard..."
echo "✅ All systems are ready! Starting the dashboard..."
echo "📊 Dashboard will be available at http://localhost:3000"
echo "📧 Email alerts are configured to use: /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "🔥 To generate test attacks, open a new terminal and run:"
echo "   ./quick-attack-test.sh"
echo ""

npm run dev
