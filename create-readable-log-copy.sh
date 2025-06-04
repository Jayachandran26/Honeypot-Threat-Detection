#!/bin/bash

echo "📋 Creating Readable Log Copy..."

# Find the actual Cowrie log file
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    ACTUAL_LOG=$(sudo lsof -p "$COWRIE_PID" | grep "cowrie.json" | awk '{print $9}')
    
    if [ -n "$ACTUAL_LOG" ]; then
        echo "Found Cowrie log: $ACTUAL_LOG"
        
        # Create a readable copy in our project directory
        READABLE_LOG="./cowrie-logs/cowrie.json"
        mkdir -p ./cowrie-logs
        
        echo "📋 Creating readable copy at: $READABLE_LOG"
        
        # Copy the log file and make it readable
        sudo cp "$ACTUAL_LOG" "$READABLE_LOG"
        sudo chown $USER:$USER "$READABLE_LOG"
        chmod 644 "$READABLE_LOG"
        
        # Set up a script to keep copying the log file
        cat > sync-logs.sh << 'EOF'
#!/bin/bash
while true; do
    COWRIE_PID=$(pgrep -f cowrie | head -1)
    if [ -n "$COWRIE_PID" ]; then
        ACTUAL_LOG=$(sudo lsof -p "$COWRIE_PID" | grep "cowrie.json" | awk '{print $9}')
        if [ -n "$ACTUAL_LOG" ] && [ -f "$ACTUAL_LOG" ]; then
            sudo cp "$ACTUAL_LOG" "./cowrie-logs/cowrie.json" 2>/dev/null
            sudo chown $USER:$USER "./cowrie-logs/cowrie.json" 2>/dev/null
        fi
    fi
    sleep 5
done
EOF
        
        chmod +x sync-logs.sh
        
        # Update environment to use our readable copy
        echo "COWRIE_LOG_PATH=$(pwd)/cowrie-logs/cowrie.json" > .env.local
        
        # Start the sync script in background
        echo "🔄 Starting log sync process..."
        ./sync-logs.sh &
        SYNC_PID=$!
        echo "Log sync started with PID: $SYNC_PID"
        
        echo "✅ Readable log copy created!"
        echo "📊 Log file: $READABLE_LOG"
        echo "📄 Current size: $(du -h "$READABLE_LOG" | cut -f1)"
        
        if [ -s "$READABLE_LOG" ]; then
            echo "📝 Sample content:"
            tail -3 "$READABLE_LOG"
        fi
        
    else
        echo "❌ Could not find Cowrie log file"
    fi
else
    echo "❌ Cowrie process not found"
fi
