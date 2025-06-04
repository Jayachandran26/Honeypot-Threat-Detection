#!/bin/bash

echo "🔧 Fixing Cowrie Configuration Paths..."

# Find Cowrie's working directory
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    COWRIE_WORKING_DIR=$(sudo lsof -p "$COWRIE_PID" | grep cwd | awk '{print $9}')
    echo "✅ Found Cowrie working directory: $COWRIE_WORKING_DIR"
    
    # The actual log file path
    ACTUAL_LOG_PATH="$COWRIE_WORKING_DIR/var/log/cowrie/cowrie.json"
    echo "📍 Actual log file should be at: $ACTUAL_LOG_PATH"
    
    # Check if it exists
    if sudo test -f "$ACTUAL_LOG_PATH"; then
        echo "✅ Log file exists!"
        echo "📊 File details:"
        sudo ls -la "$ACTUAL_LOG_PATH"
        
        # Fix permissions
        echo "🔧 Fixing permissions..."
        sudo chmod 644 "$ACTUAL_LOG_PATH"
        sudo chmod 755 "$COWRIE_WORKING_DIR/var/log/cowrie"
        sudo chmod 755 "$COWRIE_WORKING_DIR/var/log"
        sudo chmod 755 "$COWRIE_WORKING_DIR/var"
        
        # Test if we can read it now
        if [ -r "$ACTUAL_LOG_PATH" ]; then
            echo "✅ File is now readable!"
            
            # Update environment variable
            echo "📝 Updating .env.local..."
            echo "COWRIE_LOG_PATH=$ACTUAL_LOG_PATH" > .env.local
            echo "✅ Environment updated with: $ACTUAL_LOG_PATH"
            
            # Show some content if available
            if [ -s "$ACTUAL_LOG_PATH" ]; then
                echo "📝 Recent log entries:"
                tail -3 "$ACTUAL_LOG_PATH"
            else
                echo "📝 Log file is empty (normal for new installation)"
            fi
        else
            echo "❌ Still cannot read file, trying alternative approach..."
            
            # Create a readable copy
            echo "📋 Creating readable copy..."
            mkdir -p ./cowrie-logs
            sudo cp "$ACTUAL_LOG_PATH" ./cowrie-logs/cowrie.json
            sudo chown $USER:$USER ./cowrie-logs/cowrie.json
            chmod 644 ./cowrie-logs/cowrie.json
            
            # Update environment to use our copy
            echo "COWRIE_LOG_PATH=$(pwd)/cowrie-logs/cowrie.json" > .env.local
            echo "✅ Using readable copy at: $(pwd)/cowrie-logs/cowrie.json"
        fi
    else
        echo "❌ Log file not found at expected location"
        echo "🔍 Let's check what's in the log directory..."
        sudo ls -la "$COWRIE_WORKING_DIR/var/log/cowrie/" 2>/dev/null || echo "Directory not accessible"
    fi
else
    echo "❌ Cowrie process not found"
fi

# Also update Cowrie config to use absolute paths
echo ""
echo "🔧 Updating Cowrie configuration to use absolute paths..."
sudo -u cowrie bash << EOF
cd /home/cowrie/cowrie

# Backup current config
cp etc/cowrie.cfg etc/cowrie.cfg.backup

# Update config with absolute paths
sed -i 's|logfile = var/log/cowrie/cowrie.json|logfile = /home/cowrie/cowrie/var/log/cowrie/cowrie.json|g' etc/cowrie.cfg

echo "✅ Updated Cowrie configuration"
echo "📝 New JSON log configuration:"
grep -A 3 "\[output_jsonlog\]" etc/cowrie.cfg
EOF

echo ""
echo "🔄 Restarting Cowrie to apply changes..."
sudo systemctl restart cowrie
sleep 5

# Check if it's running
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie restarted successfully"
else
    echo "❌ Cowrie failed to restart"
    echo "📝 Checking logs..."
    sudo journalctl -u cowrie --no-pager -n 10
fi

echo ""
echo "✅ Configuration fix complete!"
