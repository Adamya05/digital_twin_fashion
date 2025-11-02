#!/bin/bash

# Virtual Try-On Mock Server Launch Script

echo "🚀 Starting Virtual Try-On Mock Server..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2)
REQUIRED_VERSION="18.0.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Node.js version $NODE_VERSION is not supported. Please upgrade to Node.js 18+."
    exit 1
fi

echo "✅ Node.js version: $NODE_VERSION"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
else
    echo "✅ Dependencies already installed"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚙️  Creating environment configuration..."
    cp .env.example .env
    echo "📝 Please review and update .env file with your configuration"
fi

# Check if data directory exists
if [ ! -d "data" ]; then
    mkdir -p data logs backups
    echo "✅ Created data directories"
fi

# Start the server
echo "🌟 Starting server on port ${PORT:-3000}..."
echo "📊 Health check: http://localhost:${PORT:-3000}/health"
echo "🔧 API base URL: http://localhost:${PORT:-3000}/api"
echo ""
echo "Press Ctrl+C to stop the server"
echo "----------------------------------------"

# Start in development or production mode
if [ "$NODE_ENV" = "production" ]; then
    npm start
else
    npm run dev
fi