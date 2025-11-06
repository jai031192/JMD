#!/bin/bash
# SIP Configuration Initialization Script
# This script runs after LiveKit services start to configure trunks and dispatch rules

set -e

echo "🚀 Starting SIP Configuration Initialization..."

# Wait for LiveKit services to be ready
echo "⏳ Waiting for LiveKit services to be ready..."
sleep 30

# Function to wait for service health
wait_for_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for $service_name to be healthy..."
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            echo "✅ $service_name is ready"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ $service_name failed to become ready"
    return 1
}

# Wait for LiveKit SIP service
wait_for_service "LiveKit SIP" "http://sip:8080/health"

# Check if trunk already exists
echo "🔍 Checking if Twilio trunk already exists..."
EXISTING_TRUNKS=$(lk sip trunk list --json 2>/dev/null || echo "[]")
TRUNK_EXISTS=$(echo "$EXISTING_TRUNKS" | jq -r '.[] | select(.name == "Twilio Test Trunk") | .sip_trunk_id' | head -1)

if [ ! -z "$TRUNK_EXISTS" ] && [ "$TRUNK_EXISTS" != "null" ]; then
    echo "✅ Twilio trunk already exists: $TRUNK_EXISTS"
    TRUNK_ID="$TRUNK_EXISTS"
else
    echo "📞 Creating Twilio SIP Trunk..."
    
    # Create trunk
    TRUNK_RESPONSE=$(lk sip trunk create \
        --name "Twilio Test Trunk" \
        --numbers "+13074606119" \
        --inbound-addresses "54.172.60.0/23,54.244.51.0/24,54.171.127.192/27" \
        --outbound-address "sip.twilio.com" \
        --outbound-number "+13074606119" \
        --outbound-username "$TWILIO_ACCOUNT_SID" \
        --outbound-password "$TWILIO_AUTH_TOKEN" \
        --json 2>/dev/null)
    
    TRUNK_ID=$(echo "$TRUNK_RESPONSE" | jq -r '.sip_trunk_id')
    
    if [ -z "$TRUNK_ID" ] || [ "$TRUNK_ID" = "null" ]; then
        echo "❌ Failed to create Twilio trunk"
        echo "Response: $TRUNK_RESPONSE"
        exit 1
    fi
    
    echo "✅ Twilio trunk created: $TRUNK_ID"
fi

# Check if dispatch rule already exists
echo "🔍 Checking if dispatch rule already exists..."
EXISTING_RULES=$(lk sip dispatch list --json 2>/dev/null || echo "[]")
RULE_EXISTS=$(echo "$EXISTING_RULES" | jq -r '.[] | select(.name == "Twilio Dispatch Rule") | .sip_dispatch_rule_id' | head -1)

if [ ! -z "$RULE_EXISTS" ] && [ "$RULE_EXISTS" != "null" ]; then
    echo "✅ Dispatch rule already exists: $RULE_EXISTS"
else
    echo "📋 Creating Twilio Dispatch Rule..."
    
    # Create dispatch rule
    DISPATCH_RESPONSE=$(lk sip dispatch create \
        --name "Twilio Dispatch Rule" \
        --trunk-ids "$TRUNK_ID" \
        --rule-type "individual" \
        --room-prefix "twilio-call-" \
        --json 2>/dev/null)
    
    RULE_ID=$(echo "$DISPATCH_RESPONSE" | jq -r '.sip_dispatch_rule_id')
    
    if [ -z "$RULE_ID" ] || [ "$RULE_ID" = "null" ]; then
        echo "❌ Failed to create dispatch rule"
        echo "Response: $DISPATCH_RESPONSE"
        exit 1
    fi
    
    echo "✅ Dispatch rule created: $RULE_ID"
fi

# Verify configuration
echo ""
echo "📋 Final Configuration Summary:"
echo "================================"
echo "Trunk ID: $TRUNK_ID"
echo "Rule ID: $RULE_ID"
echo "Twilio Number: +13074606119"
echo ""

echo "📞 Listing all trunks:"
lk sip trunk list

echo ""
echo "📋 Listing all dispatch rules:"
lk sip dispatch list

echo ""
echo "🎉 SIP Configuration completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Configure your Twilio phone number (+13074606119) webhook"
echo "2. Set webhook URL to: http://YOUR_PUBLIC_IP:5060"
echo "3. Ensure ports 5060 (SIP) and 10000-10100 (RTP) are open"
echo "4. Test by calling +13074606119"