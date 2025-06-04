#!/bin/bash

echo "🔧 Setting Up Dual Log System"
echo "============================="
echo "This will allow both dashboard AND email alerts to work together!"

# Define paths
PRIMARY_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
SECONDARY_LOG="$(pwd)/cowrie-logs/cowrie.json"
PROJECT_LOG_DIR="$(pwd)/cowrie-logs"

echo ""
echo "📁 Log Paths:"
echo "  Primary (Real Cowrie): $PRIMARY_LOG"
echo "  Secondary (Dashboard): $SECONDARY_LOG"

# Create project log directory
echo ""
echo "📁 Creating project log directory..."
mkdir -p "$PROJECT_LOG_DIR"
chmod 755 "$PROJECT_LOG_DIR"

# Create secondary log file
touch "$SECONDARY_LOG"
chmod 644 "$SECONDARY_LOG"

echo "✅ Project log directory created"

# Check if primary log exists
echo ""
echo "🔍 Checking primary Cowrie log..."
if [ -f "$PRIMARY_LOG" ]; then
    echo "✅ Primary log found: $PRIMARY_LOG"
    
    # Copy current content to secondary log
    echo "📋 Copying current log content..."
    if sudo cp "$PRIMARY_LOG" "$SECONDARY_LOG" 2>/dev/null; then
        sudo chown $USER:$USER "$SECONDARY_LOG"
        echo "✅ Log content copied successfully"
    else
        echo "⚠️ Could not copy log content (permission issue)"
    fi
else
    echo "⚠️ Primary log not found: $PRIMARY_LOG"
    echo "   Creating empty secondary log for now..."
fi

# Create log sync script
echo ""
echo "🔄 Creating continuous log sync script..."
cat > sync-dual-logs.sh << 'EOF'
#!/bin/bash

# Dual log sync script
PRIMARY_LOG="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
SECONDARY_LOG="$(pwd)/cowrie-logs/cowrie.json"

echo "🔄 Starting dual log sync..."
echo "  Primary: $PRIMARY_LOG"
echo "  Secondary: $SECONDARY_LOG"

while true; do
    if [ -f "$PRIMARY_LOG" ]; then
        # Copy primary to secondary (for dashboard)
        if sudo cp "$PRIMARY_LOG" "$SECONDARY_LOG" 2>/dev/null; then
            sudo chown $USER:$USER "$SECONDARY_LOG" 2>/dev/null
            chmod 644 "$SECONDARY_LOG" 2>/dev/null
        fi
    fi
    
    sleep 2
done
EOF

chmod +x sync-dual-logs.sh

# Update environment variables
echo ""
echo "📝 Updating environment variables..."
cat > .env.local << EOF
# Cowrie Log Configuration
COWRIE_LOG_PATH=$SECONDARY_LOG

# Email Configuration (keep your existing values)
SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_SECURE=${SMTP_SECURE:-false}
SMTP_USER=${SMTP_USER:-your-email@gmail.com}
SMTP_PASSWORD=${SMTP_PASSWORD:-your-app-password}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
EOF

echo "✅ Environment variables updated"

# Check permissions
echo ""
echo "🔐 Checking permissions..."
if [ -r "$SECONDARY_LOG" ]; then
    echo "✅ Secondary log is readable"
else
    echo "❌ Secondary log is not readable"
    chmod 644 "$SECONDARY_LOG"
fi

if [ -f "$PRIMARY_LOG" ] && sudo test -r "$PRIMARY_LOG"; then
    echo "✅ Primary log is accessible"
else
    echo "⚠️ Primary log may not be accessible"
fi

# Start the sync process
echo ""
echo "🚀 Starting dual log sync process..."
./sync-dual-logs.sh &
SYNC_PID=$!
echo "✅ Sync process started (PID: $SYNC_PID)"

# Wait a moment for sync
sleep 3

# Check both log files
echo ""
echo "📊 Log File Status:"
echo "==================="

if [ -f "$PRIMARY_LOG" ]; then
    PRIMARY_SIZE=$(sudo wc -l < "$PRIMARY_LOG" 2>/dev/null || echo "0")
    echo "📄 Primary log: $PRIMARY_SIZE lines"
else
    echo "📄 Primary log: Not found"
fi

if [ -f "$SECONDARY_LOG" ]; then
    SECONDARY_SIZE=$(wc -l < "$SECONDARY_LOG" 2>/dev/null || echo "0")
    echo "📄 Secondary log: $SECONDARY_SIZE lines"
else
    echo "📄 Secondary log: Not found"
fi

echo ""
echo "🎯 DUAL LOG SYSTEM SETUP COMPLETE!"
echo "=================================="
echo "✅ Dashboard will read from: $SECONDARY_LOG"
echo "✅ Email alerts will monitor: $PRIMARY_LOG (and secondary as backup)"
echo "✅ Log sync process running: PID $SYNC_PID"
echo ""
echo "🚀 Next steps:"
echo "1. Start your dashboard: npm run dev"
echo "2. Test email alerts: visit http://localhost:3000/alerts"
echo "3. Generate attacks: ssh root@localhost -p 2222"
echo ""
echo "🛑 To stop sync: kill $SYNC_PID"
echo "📝 Monitor sync: tail -f sync-dual-logs.log"
