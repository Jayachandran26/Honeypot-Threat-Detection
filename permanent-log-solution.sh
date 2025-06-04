#!/bin/bash

echo "🔧 PERMANENT Cowrie Log Solution"
echo "================================"
echo "Creating accessible log directory and configuring Cowrie to use it"

# Create a dedicated log directory in our project
LOG_DIR="$(pwd)/cowrie-logs"
LOG_FILE="$LOG_DIR/cowrie.json"

echo "📁 Creating dedicated log directory: $LOG_DIR"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Create the log file
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

echo "✅ Created accessible log directory and file"
echo "📍 Log directory: $LOG_DIR"
echo "📄 Log file: $LOG_FILE"

# Find the actual Cowrie installation
echo ""
echo "🔍 Finding Cowrie installation..."
COWRIE_PATH=""

# Check if Cowrie is running and get its working directory
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    COWRIE_WORKING_DIR=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep cwd | awk '{print $9}')
    if [ -n "$COWRIE_WORKING_DIR" ] && [ -d "$COWRIE_WORKING_DIR" ]; then
        COWRIE_PATH="$COWRIE_WORKING_DIR"
        echo "✅ Found Cowrie working directory: $COWRIE_PATH"
    fi
fi

# If not found, check common locations
if [ -z "$COWRIE_PATH" ]; then
    possible_paths=(
        "/home/jayachandran/cowrie"
        "/home/cowrie/cowrie"
        "/opt/cowrie"
        "/usr/local/cowrie"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ]; then
            COWRIE_PATH="$path"
            echo "✅ Found Cowrie at: $COWRIE_PATH"
            break
        fi
    done
fi

if [ -z "$COWRIE_PATH" ]; then
    echo "❌ Could not find Cowrie installation"
    exit 1
fi

# Stop Cowrie temporarily
echo ""
echo "🛑 Stopping Cowrie temporarily..."
sudo systemctl stop cowrie 2>/dev/null || true
sleep 3

# Update Cowrie configuration to use our accessible log file
echo "⚙️ Updating Cowrie configuration..."

# Check if we can write to Cowrie config as the current user or need sudo
if [ -w "$COWRIE_PATH/etc/cowrie.cfg" ]; then
    # We can write directly
    WRITE_CMD=""
else
    # Need to use sudo
    WRITE_CMD="sudo"
fi

# Backup existing config
$WRITE_CMD cp "$COWRIE_PATH/etc/cowrie.cfg" "$COWRIE_PATH/etc/cowrie.cfg.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Update the JSON log configuration
echo "📝 Updating JSON log configuration..."
$WRITE_CMD sed -i "s|^logfile = .*|logfile = $LOG_FILE|g" "$COWRIE_PATH/etc/cowrie.cfg" 2>/dev/null || {
    # If sed fails, create a new config section
    echo ""
    echo "[output_jsonlog]"
    echo "enabled = true"
    echo "logfile = $LOG_FILE"
    echo "epoch_timestamp = true"
} | $WRITE_CMD tee -a "$COWRIE_PATH/etc/cowrie.cfg" > /dev/null

# Verify the configuration
echo "🔍 Verifying configuration..."
if grep -q "$LOG_FILE" "$COWRIE_PATH/etc/cowrie.cfg"; then
    echo "✅ Configuration updated successfully"
    echo "📝 JSON log will be written to: $LOG_FILE"
else
    echo "⚠️ Configuration update may have failed, manually updating..."
    
    # Manual configuration update
    $WRITE_CMD bash -c "cat >> '$COWRIE_PATH/etc/cowrie.cfg' << EOF

# Custom JSON logging configuration
[output_jsonlog]
enabled = true
logfile = $LOG_FILE
epoch_timestamp = true
EOF"
fi

# Set up environment variable
echo "📝 Setting up environment variable..."
echo "COWRIE_LOG_PATH=$LOG_FILE" > .env.local
echo "✅ Environment configured: COWRIE_LOG_PATH=$LOG_FILE"

# Create a log sync script to continuously copy logs
echo "🔄 Creating log sync script..."
cat > sync-cowrie-logs.sh << 'EOF'
#!/bin/bash

# Log sync script - copies Cowrie logs to our accessible directory
LOG_FILE="$(pwd)/cowrie-logs/cowrie.json"

while true; do
    # Find Cowrie process and its log files
    COWRIE_PID=$(pgrep -f cowrie | head -1)
    if [ -n "$COWRIE_PID" ]; then
        # Find any JSON log files that Cowrie has open
        COWRIE_LOGS=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep "\.json" | awk '{print $9}')
        
        for log in $COWRIE_LOGS; do
            if [ -f "$log" ] && [ -s "$log" ]; then
                # Copy the log file to our accessible location
                sudo cp "$log" "$LOG_FILE" 2>/dev/null
                sudo chown $USER:$USER "$LOG_FILE" 2>/dev/null
                chmod 644 "$LOG_FILE" 2>/dev/null
            fi
        done
    fi
    
    sleep 2
done
EOF

chmod +x sync-cowrie-logs.sh

# Start Cowrie
echo ""
echo "🚀 Starting Cowrie with new configuration..."
sudo systemctl start cowrie
sleep 5

# Check if Cowrie is running
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is running!"
    
    # Start the log sync script in background
    echo "🔄 Starting log sync process..."
    ./sync-cowrie-logs.sh &
    SYNC_PID=$!
    echo "Log sync started with PID: $SYNC_PID"
    
    # Wait a moment for initial sync
    sleep 3
    
    # Check our log file
    if [ -f "$LOG_FILE" ]; then
        echo "✅ Log file created: $LOG_FILE"
        echo "📊 File permissions: $(ls -la "$LOG_FILE")"
        
        if [ -r "$LOG_FILE" ]; then
            echo "✅ Log file is readable!"
            if [ -s "$LOG_FILE" ]; then
                echo "📝 File has content ($(wc -l < "$LOG_FILE") lines)"
            else
                echo "📝 File is empty (waiting for attacks)"
            fi
        else
            echo "❌ Log file is not readable"
        fi
    else
        echo "⚠️ Log file not created yet, will be created on first attack"
    fi
    
    # Show Cowrie status
    echo ""
    echo "📊 Cowrie Status:"
    echo "  Process: $(ps aux | grep cowrie | grep -v grep | wc -l) running"
    echo "  SSH Port: $(ss -ln | grep :2222 > /dev/null && echo "✅ Listening" || echo "❌ Not listening")"
    echo "  Telnet Port: $(ss -ln | grep :2223 > /dev/null && echo "✅ Listening" || echo "❌ Not listening")"
    
else
    echo "❌ Cowrie failed to start"
    echo "📝 Checking logs..."
    sudo journalctl -u cowrie --no-pager -n 10
fi

echo ""
echo "🎯 PERMANENT SOLUTION COMPLETE!"
echo "================================"
echo "📁 Accessible log directory: $LOG_DIR"
echo "📄 Accessible log file: $LOG_FILE"
echo "🔄 Log sync process: Running (PID: $SYNC_PID)"
echo "📊 Dashboard: http://localhost:3000"
echo ""
echo "🧪 Test the honeypot:"
echo "  ssh root@localhost -p 2222 (password: admin)"
echo "  ssh admin@localhost -p 2222 (password: password)"
echo ""
echo "📝 Monitor logs: tail -f $LOG_FILE"
echo "🛑 Stop log sync: kill $SYNC_PID"
