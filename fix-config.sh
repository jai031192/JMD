#!/bin/bash
# Quick fix script for Docker config file mounting issue

echo "🔧 Fixing LiveKit Docker Configuration..."

# Stop all containers
echo "Stopping all containers..."
docker-compose down

# Remove any incorrectly created config directories
echo "Cleaning up incorrect config directories..."
sudo rm -rf config.yaml sip-config.yaml egress-config.yaml ingress-config.yaml 2>/dev/null

# Pull the fixed docker-compose.yml
echo "Pulling latest configuration from GitHub..."
git pull origin main

# Restart services
echo "Starting services with fixed configuration..."
docker-compose --profile full up -d

echo ""
echo "✅ Fix applied! Checking status..."
docker-compose ps

echo ""
echo "📋 View logs:"
echo "  docker-compose logs -f sip"
echo "  docker-compose logs -f egress"
echo "  docker-compose logs -f ingress"
