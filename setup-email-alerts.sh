#!/bin/bash

echo "📧 Setting up Email Alert System..."

# Install nodemailer for email functionality
echo "📦 Installing email dependencies..."
npm install nodemailer @types/nodemailer

# Create environment template
echo "📝 Creating environment template..."
cat > .env.example << 'EOF'
# Cowrie Log Path
COWRIE_LOG_PATH=./cowrie-logs/cowrie.json

# Email Configuration for Alerts
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
ADMIN_EMAIL=admin@yourdomain.com
EOF

# Check if .env.local exists and add email config if missing
if [ -f ".env.local" ]; then
    echo "📝 Updating existing .env.local..."
    
    # Add email config if not present
    if ! grep -q "SMTP_HOST" .env.local; then
        echo "" >> .env.local
        echo "# Email Configuration for Alerts" >> .env.local
        echo "SMTP_HOST=smtp.gmail.com" >> .env.local
        echo "SMTP_PORT=587" >> .env.local
        echo "SMTP_SECURE=false" >> .env.local
        echo "SMTP_USER=" >> .env.local
        echo "SMTP_PASSWORD=" >> .env.local
        echo "ADMIN_EMAIL=" >> .env.local
    fi
else
    echo "📝 Creating .env.local..."
    cp .env.example .env.local
fi

# Create alert startup script
echo "🚀 Creating alert startup script..."
cat > start-with-alerts.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Cowrie Honeypot with Email Alerts..."

# Check if log sync is running
if ! pgrep -f "sync-cowrie-logs.sh" > /dev/null; then
    echo "🔄 Starting log sync process..."
    ./sync-cowrie-logs.sh &
    echo "Log sync started with PID: $!"
fi

# Check if Cowrie is running
if ! systemctl is-active --quiet cowrie; then
    echo "🚀 Starting Cowrie..."
    sudo systemctl start cowrie
    sleep 5
fi

# Kill any existing dev server
pkill -f "next dev" 2>/dev/null || true
sleep 2

# Start the dashboard
echo "📊 Starting dashboard with alert system..."
npm run dev &
DEV_PID=$!

# Wait for dashboard to start
sleep 10

# Start alert monitoring
echo "🚨 Starting alert monitoring..."
curl -X POST http://localhost:3000/api/alerts/monitor > /dev/null 2>&1

echo ""
echo "✅ Complete system started!"
echo "📊 Dashboard: http://localhost:3000"
echo "🚨 Alerts: http://localhost:3000/alerts"
echo "📝 Log file: $(pwd)/cowrie-logs/cowrie.json"
echo "🎯 Test honeypot: ssh root@localhost -p 2222"
echo ""
echo "🛑 To stop:"
echo "  Dashboard: kill $DEV_PID"
echo "  Log sync: pkill -f sync-cowrie-logs.sh"
echo "  Alerts: curl -X DELETE http://localhost:3000/api/alerts/monitor"
EOF

chmod +x start-with-alerts.sh

# Create test alert script
echo "🧪 Creating test alert script..."
cat > test-email-alerts.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Email Alert System..."

# Check if development server is running
if ! pgrep -f "next dev" > /dev/null; then
    echo "❌ Development server not running. Start it first with:"
    echo "   npm run dev"
    exit 1
fi

# Test email configuration
echo "📧 Testing email configuration..."
curl -X POST http://localhost:3000/api/alerts/test

echo ""
echo "📝 Check your email for the test alert!"
echo "If you don't receive it, check your email configuration in the dashboard."
EOF

chmod +x test-email-alerts.sh

echo ""
echo "✅ Email Alert System Setup Complete!"
echo "=================================="
echo ""
echo "📋 Next Steps:"
echo "1. Configure your email settings:"
echo "   - Edit .env.local with your SMTP details"
echo "   - For Gmail: Enable 2FA and create an App Password"
echo ""
echo "2. Start the complete system:"
echo "   ./start-with-alerts.sh"
echo ""
echo "3. Configure alerts in the dashboard:"
echo "   http://localhost:3000/alerts"
echo ""
echo "4. Test email alerts:"
echo "   ./test-email-alerts.sh"
echo ""
echo "📧 Gmail Setup Instructions:"
echo "   1. Go to Google Account → Security → 2-Step Verification"
echo "   2. Enable 2-Step Verification"
echo "   3. Go to App passwords and generate one for 'Mail'"
echo "   4. Use that App Password in SMTP_PASSWORD"
echo ""
echo "🎯 Generate attacks to test:"
echo "   ssh root@localhost -p 2222 (password: admin)"
echo "   ssh admin@localhost -p 2222 (password: password)"
