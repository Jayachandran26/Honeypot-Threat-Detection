#!/bin/bash

echo "🔍 Verifying Log Setup..."

# Check current environment
echo "📝 Current environment:"
cat .env.local 2>/dev/null || echo "No .env.local file found"

echo ""
echo "🔍 Checking Cowrie process and files..."
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    echo "✅ Cowrie is running (PID: $COWRIE_PID)"
    
    echo "📂 Files opened by Cowrie:"
    sudo lsof -p "$COWRIE_PID" | grep -E "\.(json|log)$"
    
    # Get the actual log file path from lsof
    ACTUAL_LOG=$(sudo lsof -p "$COWRIE_PID" | grep "cowrie.json" | awk '{print $9}')
    if [ -n "$ACTUAL_LOG" ]; then
        echo "📍 Cowrie is actually using: $ACTUAL_LOG"
        
        # Check if we can read it
        if [ -r "$ACTUAL_LOG" ]; then
            echo "✅ File is readable!"
            echo "📊 Size: $(du -h "$ACTUAL_LOG" | cut -f1)"
            echo "📄 Lines: $(wc -l < "$ACTUAL_LOG")"
        else
            echo "❌ File is not readable by current user"
            echo "🔒 Permissions: $(ls -la "$ACTUAL_LOG")"
        fi
        
        # Update environment with the correct path
        echo "COWRIE_LOG_PATH=$ACTUAL_LOG" > .env.local
        echo "✅ Updated .env.local with actual path"
    fi
else
    echo "❌ Cowrie is not running"
fi

echo ""
echo "🧪 Testing API endpoints..."
if pgrep -f "next dev" > /dev/null; then
    echo "Testing status endpoint..."
    curl -s http://localhost:3000/api/cowrie/status | jq .logFileExists 2>/dev/null || echo "API test failed"
    
    echo "Testing events endpoint..."
    curl -s http://localhost:3000/api/cowrie/events | jq .success 2>/dev/null || echo "API test failed"
else
    echo "⚠️ Development server not running"
fi

echo ""
echo "✅ Verification complete!"
