#!/bin/bash

echo "🔄 RESTARTING APPLICATION WITH NEW ENVIRONMENT"
echo "=============================================="

# Kill any existing Next.js processes
echo "🛑 Stopping existing application..."
pkill -f "next dev" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true
sleep 3

# Check if .env.local exists and has content
if [ ! -f .env.local ]; then
    echo "❌ .env.local file not found!"
    echo "Please run ./setup-email-environment.sh first"
    exit 1
fi

if [ ! -s .env.local ]; then
    echo "❌ .env.local file is empty!"
    echo "Please run ./setup-email-environment.sh first"
    exit 1
fi

echo "✅ Found .env.local configuration:"
echo "=================================="
# Show config without passwords
grep -v "SMTP_PASSWORD" .env.local
echo "SMTP_PASSWORD=***CONFIGURED***"
echo "=================================="
echo

# Clear Next.js cache
echo "🧹 Clearing Next.js cache..."
rm -rf .next
echo "✅ Cache cleared"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "🚀 Starting application with new environment..."
echo "📊 Dashboard will be available at: http://localhost:3000"
echo "📧 Email alerts page: http://localhost:3000/alerts"
echo ""
echo "⏳ Starting in 3 seconds..."
sleep 3

# Start with explicit environment loading
npm run dev
