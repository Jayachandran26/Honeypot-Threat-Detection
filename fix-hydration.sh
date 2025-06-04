#!/bin/bash

echo "🔧 Fixing hydration issues in Cowrie Honeypot Dashboard..."

# Clear Next.js cache
echo "🧹 Clearing Next.js cache..."
rm -rf .next
rm -rf node_modules/.cache

# Reinstall dependencies
echo "📦 Reinstalling dependencies..."
npm install

# Build the project
echo "🏗️ Building the project..."
npm run build

# Start development server
echo "🚀 Starting development server..."
npm run dev

echo "✅ Hydration issues should be resolved!"
echo "📊 Dashboard available at: http://localhost:3000"
