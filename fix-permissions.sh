#!/bin/bash

echo "🔧 Fixing File Permissions..."

LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

# Create log file if it doesn't exist
if [ ! -f "$LOG_PATH" ]; then
    echo "📝 Creating log file..."
    sudo -u cowrie touch "$LOG_PATH"
fi

# Fix permissions
echo "🔒 Setting proper permissions..."
sudo chmod 644 "$LOG_PATH"
sudo chown cowrie:cowrie "$LOG_PATH"

# Make sure the directory is accessible
sudo chmod 755 /home/cowrie/cowrie/var/log/cowrie
sudo chmod 755 /home/cowrie/cowrie/var/log
sudo chmod 755 /home/cowrie/cowrie/var

echo "✅ Permissions fixed!"
echo "📊 File info:"
ls -la "$LOG_PATH"
