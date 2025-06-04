#!/bin/bash

echo "🔧 Updating Dashboard Configuration..."

# Set the correct log path
LOG_PATH="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"

# Update environment file
echo "📝 Updating .env.local..."
cat > .env.local << EOF
COWRIE_LOG_PATH=$LOG_PATH
EOF

echo "✅ Environment updated with: $LOG_PATH"

# Test API endpoints
echo "🧪 Testing API endpoints..."

# Start the development server in background if not running
if ! pgrep -f "next dev" > /dev/null; then
    echo "🚀 Starting development server..."
    npm run dev &
    DEV_PID=$!
    sleep 10
    echo "Development server started with PID: $DEV_PID"
else
    echo "✅ Development server already running"
fi

# Test the API endpoints
echo "Testing Cowrie status API..."
curl -s http://localhost:3000/api/cowrie/status | jq . 2>/dev/null || curl -s http://localhost:3000/api/cowrie/status

echo ""
echo "Testing Cowrie events API..."
curl -s http://localhost:3000/api/cowrie/events | jq . 2>/dev/null || curl -s http://localhost:3000/api/cowrie/events

echo ""
echo "✅ Dashboard configuration updated!"
echo "📊 Dashboard: http://localhost:3000"
