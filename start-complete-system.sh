#!/bin/bash

echo "🚀 Starting Complete Cowrie Honeypot System with Email Alerts"
echo "============================================================"

# Check if environment variables are set
check_env_var() {
    if [ -z "${!1}" ]; then
        echo "⚠️  Warning: $1 is not set"
        return 1
    else
        echo "✅ $1 is configured"
        return 0
    fi
}

echo "🔍 Checking environment configuration..."
ENV_OK=true

# Check required environment variables
if ! check_env_var "COWRIE_LOG_PATH"; then ENV_OK=false; fi
if ! check_env_var "SMTP_HOST"; then ENV_OK=false; fi
if ! check_env_var "SMTP_USER"; then ENV_OK=false; fi
if ! check_env_var "SMTP_PASSWORD"; then ENV_OK=false; fi
if ! check_env_var "ADMIN_EMAIL"; then ENV_OK=false; fi

if [ "$ENV_OK" = false ]; then
    echo ""
    echo "❌ Some environment variables are missing!"
    echo "Please configure them in your Vercel project or .env.local file"
    echo ""
    echo "Required variables:"
    echo "- COWRIE_LOG_PATH: Path to Cowrie JSON log file"
    echo "- SMTP_HOST: SMTP server hostname (e.g., smtp.gmail.com)"
    echo "- SMTP_USER: SMTP username/email"
    echo "- SMTP_PASSWORD: SMTP password (use App Password for Gmail)"
    echo "- ADMIN_EMAIL: Email address to receive alerts"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if log sync is running
if ! pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "🔄 Starting log sync process..."
    if [ -f "./sync-cowrie-logs.sh" ]; then
        ./sync-cowrie-logs.sh &
        echo "Log sync started with PID: $!"
    else
        echo "⚠️  sync-cowrie-logs.sh not found, creating it..."
        cat > sync-cowrie-logs.sh << 'EOF'
#!/bin/bash
LOG_FILE="$(pwd)/cowrie-logs/cowrie.json"
mkdir -p "$(dirname "$LOG_FILE")"

while true; do
    COWRIE_PID=$(pgrep -f cowrie | head -1)
    if [ -n "$COWRIE_PID" ]; then
        COWRIE_LOGS=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep "\.json" | awk '{print $9}')
        for log in $COWRIE_LOGS; do
            if [ -f "$log" ] && [ -s "$log" ]; then
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
        ./sync-cowrie-logs.sh &
        echo "Log sync started with PID: $!"
    fi
fi

# Check if Cowrie is running
if ! systemctl is-active --quiet cowrie 2>/dev/null; then
    echo "🚀 Starting Cowrie honeypot..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start cowrie
        sleep 5
        
        if systemctl is-active --quiet cowrie; then
            echo "✅ Cowrie started successfully"
        else
            echo "❌ Failed to start Cowrie"
            echo "📝 Checking Cowrie logs..."
            sudo journalctl -u cowrie --no-pager -n 10
        fi
    else
        echo "⚠️  systemctl not available, please start Cowrie manually"
    fi
else
    echo "✅ Cowrie is already running"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Kill any existing dev server
echo "🛑 Stopping any existing development server..."
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start the dashboard
echo "📊 Starting dashboard with alert system..."
npm run dev &
DEV_PID=$!

# Wait for dashboard to start
echo "⏳ Waiting for dashboard to start..."
sleep 15

# Check if dashboard is running
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Dashboard is running"
    
    # Initialize alert monitoring
    echo "🚨 Initializing alert monitoring..."
    MONITOR_RESPONSE=$(curl -s -X POST http://localhost:3000/api/alerts/monitor)
    if echo "$MONITOR_RESPONSE" | grep -q '"success":true'; then
        echo "✅ Alert monitoring started successfully"
    else
        echo "⚠️  Alert monitoring may not have started properly"
        echo "Response: $MONITOR_RESPONSE"
    fi
    
    # Test email configuration
    echo "📧 Testing email configuration..."
    EMAIL_TEST=$(curl -s -X POST http://localhost:3000/api/alerts/test)
    if echo "$EMAIL_TEST" | grep -q '"success":true'; then
        echo "✅ Email test sent successfully! Check your inbox."
    else
        echo "⚠️  Email test failed. Please check your SMTP configuration."
        echo "Response: $EMAIL_TEST"
    fi
else
    echo "❌ Dashboard failed to start"
fi

# Show system status
echo ""
echo "🎯 SYSTEM STATUS"
echo "================"
echo "📊 Dashboard: http://localhost:3000"
echo "🚨 Alert Management: http://localhost:3000/alerts"
echo "📝 Log file: ${COWRIE_LOG_PATH:-./cowrie-logs/cowrie.json}"
echo ""
echo "🔍 Honeypot Endpoints:"
echo "   SSH: ssh root@localhost -p 2222"
echo "   Telnet: telnet localhost 2223"
echo ""
echo "🧪 Test Commands:"
echo "   ssh root@localhost -p 2222 (password: admin)"
echo "   ssh admin@localhost -p 2222 (password: password)"
echo ""
echo "📧 Email Alerts:"
echo "   Admin Email: ${ADMIN_EMAIL:-Not configured}"
echo "   SMTP Host: ${SMTP_HOST:-Not configured}"
echo ""
echo "🛑 To Stop System:"
echo "   Dashboard: kill $DEV_PID"
echo "   Log Sync: pkill -f sync-cowrie-logs.sh"
echo "   Cowrie: sudo systemctl stop cowrie"
echo ""
echo "✅ Complete system is now running!"
echo "Generate some attacks to test the email alerts! 🎯"
