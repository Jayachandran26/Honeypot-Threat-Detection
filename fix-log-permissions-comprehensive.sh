#!/bin/bash

echo "🔧 Comprehensive Log Permissions Fix..."

# First, let's see what's actually happening
echo "🔍 Current situation analysis..."

# Check if we can access the cowrie user's home directory
echo "Checking access to /home/cowrie..."
if sudo test -d "/home/cowrie"; then
    echo "✅ /home/cowrie exists"
    sudo ls -la /home/cowrie/
else
    echo "❌ /home/cowrie not accessible"
fi

# Check the actual log file that Cowrie is using
echo ""
echo "🔍 Finding the actual log file Cowrie is using..."
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    echo "Cowrie PID: $COWRIE_PID"
    echo "Files opened by Cowrie:"
    sudo lsof -p "$COWRIE_PID" | grep -E "\.(json|log)$"
    
    # Get the actual log file path
    ACTUAL_LOG=$(sudo lsof -p "$COWRIE_PID" | grep "cowrie.json" | awk '{print $9}')
    echo "Actual log file: $ACTUAL_LOG"
    
    if [ -n "$ACTUAL_LOG" ]; then
        echo "📊 Log file details:"
        sudo ls -la "$ACTUAL_LOG"
        echo "📄 File size: $(sudo du -h "$ACTUAL_LOG" | cut -f1)"
        
        # Make it readable by everyone
        echo "🔧 Making log file readable..."
        sudo chmod 644 "$ACTUAL_LOG"
        
        # Also make parent directories accessible
        echo "🔧 Making parent directories accessible..."
        sudo chmod 755 "$(dirname "$ACTUAL_LOG")"
        sudo chmod 755 "$(dirname "$(dirname "$ACTUAL_LOG")")"
        sudo chmod 755 "$(dirname "$(dirname "$(dirname "$ACTUAL_LOG")")")"
        
        # Test if we can read it now
        echo "🧪 Testing file access..."
        if [ -r "$ACTUAL_LOG" ]; then
            echo "✅ File is now readable!"
            echo "📝 Last few lines:"
            tail -3 "$ACTUAL_LOG" 2>/dev/null || echo "File is empty or no content yet"
        else
            echo "❌ Still cannot read file"
        fi
        
        # Update environment file with correct path
        echo "📝 Updating .env.local with correct path..."
        echo "COWRIE_LOG_PATH=$ACTUAL_LOG" > .env.local
        echo "✅ Environment updated with: $ACTUAL_LOG"
    fi
else
    echo "❌ Cowrie process not found"
fi

echo ""
echo "✅ Comprehensive fix complete!"
