#!/bin/bash
# Automated SIP Setup - Complete Deployment Script

set -e

echo "🚀 Starting Automated LiveKit SIP Setup with Twilio Integration"
echo "================================================================"

# Check if .env exists
if [ ! -f .env ]; then
    echo "📋 Creating .env file from template..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Please update .env file with your actual credentials:"
    echo "   - LIVEKIT_URL"
    echo "   - LIVEKIT_API_KEY"
    echo "   - LIVEKIT_API_SECRET"
    echo "   - TWILIO_ACCOUNT_SID"
    echo "   - TWILIO_AUTH_TOKEN"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Load environment variables
source .env

# Verify required variables
echo "🔍 Verifying configuration..."
missing_vars=0

check_var() {
    if [ -z "${!1}" ]; then
        echo "❌ Missing: $1"
        missing_vars=1
    else
        echo "✅ Found: $1"
    fi
}

check_var "LIVEKIT_URL"
check_var "LIVEKIT_API_KEY"
check_var "LIVEKIT_API_SECRET"
check_var "TWILIO_ACCOUNT_SID"
check_var "TWILIO_AUTH_TOKEN"

if [ $missing_vars -eq 1 ]; then
    echo ""
    echo "❌ Please update .env file with missing variables"
    exit 1
fi

echo ""
echo "✅ Configuration verified!"

# Check if Docker is running
echo ""
echo "🐳 Checking Docker..."
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "✅ Docker is running"

# Pull latest images
echo ""
echo "📥 Pulling latest Docker images..."
docker-compose pull

# Stop existing services
echo ""
echo "🛑 Stopping any existing services..."
docker-compose down --remove-orphans

# Start services
echo ""
echo "🚀 Starting LiveKit SIP services..."
docker-compose up -d redis sip

# Wait for core services to be healthy
echo ""
echo "⏳ Waiting for core services to be ready..."
sleep 30

# Start the initialization service
echo ""
echo "⚙️  Starting SIP configuration initialization..."
docker-compose up sip-init

# Check if initialization was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SIP Configuration completed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "====================="
    echo "✅ Redis: Running on port 6379"
    echo "✅ SIP Service: Running on port 5060"
    echo "✅ RTP Ports: 10000-10100"
    echo "✅ Health Check: http://localhost:8080/health"
    echo "✅ Twilio Trunk: Created for +13074606119"
    echo "✅ Dispatch Rule: Created with prefix 'twilio-call-'"
    echo ""
    echo "📞 Next Steps:"
    echo "1. Configure Twilio webhook URL: http://YOUR_PUBLIC_IP:5060"
    echo "2. Ensure firewall allows ports 5060 and 10000-10100"
    echo "3. Test by calling +13074606119"
    echo ""
    echo "🔧 Management Commands:"
    echo "  View logs: docker-compose logs -f sip"
    echo "  List trunks: docker exec livekit-cli lk sip trunk list"
    echo "  List rules: docker exec livekit-cli lk sip dispatch list"
    echo "  Stop services: docker-compose down"
else
    echo ""
    echo "❌ SIP Configuration failed!"
    echo "Check logs: docker-compose logs sip-init"
    exit 1
fi

# Show service status
echo ""
echo "📊 Service Status:"
docker-compose ps