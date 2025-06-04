#!/bin/bash

echo "🔧 Fixing Cowrie Directory Access..."

# Check the actual working directory from the systemd service
echo "🔍 Finding Cowrie working directory..."
WORKING_DIR=$(systemctl show cowrie -p WorkingDirectory --value)
echo "Working directory from systemd: $WORKING_DIR"

# Check what the cowrie user can see
echo "🔍 Checking as cowrie user..."
sudo -u cowrie bash << 'EOF'
echo "Current directory: $(pwd)"
echo "Home directory: $HOME"
echo "Contents of home directory:"
ls -la $HOME/
if [ -d "$HOME/cowrie" ]; then
    echo "✅ Found cowrie directory"
    echo "Contents of cowrie directory:"
    ls -la $HOME/cowrie/
    if [ -d "$HOME/cowrie/var" ]; then
        echo "Contents of var directory:"
        ls -la $HOME/cowrie/var/
        if [ -d "$HOME/cowrie/var/log" ]; then
            echo "Contents of log directory:"
            ls -la $HOME/cowrie/var/log/
            if [ -d "$HOME/cowrie/var/log/cowrie" ]; then
                echo "Contents of cowrie log directory:"
                ls -la $HOME/cowrie/var/log/cowrie/
            fi
        fi
    fi
else
    echo "❌ Cowrie directory not found in home"
fi
EOF

# Try to find where Cowrie is actually running from
echo ""
echo "🔍 Finding actual Cowrie location from process..."
COWRIE_PROC=$(ps aux | grep cowrie | grep -v grep | head -1)
echo "Cowrie process: $COWRIE_PROC"

# Extract the working directory from the process
COWRIE_DIR=$(sudo lsof -p $(pgrep -f cowrie | head -1) 2>/dev/null | grep cwd | awk '{print $9}')
if [ -n "$COWRIE_DIR" ]; then
    echo "✅ Found Cowrie working directory: $COWRIE_DIR"
    echo "Contents:"
    sudo ls -la "$COWRIE_DIR"
    
    # Check for log directory
    if [ -d "$COWRIE_DIR/var/log/cowrie" ]; then
        echo "✅ Found log directory: $COWRIE_DIR/var/log/cowrie"
        sudo ls -la "$COWRIE_DIR/var/log/cowrie/"
    fi
else
    echo "❌ Could not determine working directory"
fi

# Try alternative approach - check systemd service file
echo ""
echo "🔍 Checking systemd service configuration..."
if [ -f "/etc/systemd/system/cowrie.service" ]; then
    echo "Service file contents:"
    cat /etc/systemd/system/cowrie.service
fi

# Create the log file if it doesn't exist
echo ""
echo "🔧 Creating log file if needed..."
sudo -u cowrie bash << 'EOF'
if [ -d "$HOME/cowrie" ]; then
    mkdir -p "$HOME/cowrie/var/log/cowrie"
    touch "$HOME/cowrie/var/log/cowrie/cowrie.json"
    echo "✅ Created log file: $HOME/cowrie/var/log/cowrie/cowrie.json"
    ls -la "$HOME/cowrie/var/log/cowrie/cowrie.json"
else
    echo "❌ Cannot create log file - cowrie directory not found"
fi
EOF

echo ""
echo "🔧 Fix complete!"
