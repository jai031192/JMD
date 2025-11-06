#!/bin/bash
# Advanced SIP Configuration Initialization using API
# This ensures proper trunk and dispatch rule creation with full configuration

set -e

echo "🚀 Starting Advanced SIP Configuration..."

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 45

# Function to check service health
check_service_health() {
    local service_url=$1
    local service_name=$2
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$service_url" > /dev/null 2>&1; then
            echo "✅ $service_name is healthy"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: Waiting for $service_name..."
        sleep 15
        ((attempt++))
    done
    
    echo "❌ $service_name failed health check"
    return 1
}

# Check LiveKit SIP service health
check_service_health "http://sip:8080/health" "LiveKit SIP"

# Convert WebSocket URL to HTTP
HTTP_URL=$(echo "$LIVEKIT_URL" | sed 's/wss:/https:/' | sed 's/ws:/http:/')

echo "🔑 Generating authentication token..."
TOKEN=$(lk token create \
    --create-sip-trunk \
    --list-sip-trunk \
    --create-sip-dispatch \
    --list-sip-dispatch \
    --join --room "*" \
    --identity "sip-config-bot" \
    --ttl 1h)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to generate authentication token"
    exit 1
fi

echo "✅ Token generated successfully"

# Create Twilio Trunk using API
echo "📞 Creating Twilio SIP Trunk via API..."

TRUNK_JSON='{
  "trunk": {
    "name": "Twilio Test Trunk",
    "numbers": ["+13074606119"],
    "inbound_addresses": ["54.172.60.0/23", "54.244.51.0/24", "54.171.127.192/27"],
    "outbound_address": "sip.twilio.com",
    "outbound_number": "+13074606119",
    "inbound_username": "",
    "inbound_password": "",
    "outbound_username": "'$TWILIO_ACCOUNT_SID'",
    "outbound_password": "'$TWILIO_AUTH_TOKEN'",
    "krisp_enabled": true
  }
}'

TRUNK_RESPONSE=$(curl -s -X POST "$HTTP_URL/sip/create_trunk" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$TRUNK_JSON")

echo "Trunk creation response: $TRUNK_RESPONSE"

TRUNK_ID=$(echo "$TRUNK_RESPONSE" | jq -r '.sip_trunk_id // .trunk.sip_trunk_id // empty')

if [ -z "$TRUNK_ID" ] || [ "$TRUNK_ID" = "null" ]; then
    echo "⚠️ Trunk creation may have failed, checking existing trunks..."
    
    # Try to find existing trunk
    EXISTING_RESPONSE=$(curl -s -X GET "$HTTP_URL/sip/list_trunk" \
        -H "Authorization: Bearer $TOKEN")
    
    TRUNK_ID=$(echo "$EXISTING_RESPONSE" | jq -r '.[] | select(.name == "Twilio Test Trunk") | .sip_trunk_id' | head -1)
    
    if [ ! -z "$TRUNK_ID" ] && [ "$TRUNK_ID" != "null" ]; then
        echo "✅ Found existing Twilio trunk: $TRUNK_ID"
    else
        echo "❌ Failed to create or find Twilio trunk"
        echo "Response: $TRUNK_RESPONSE"
        exit 1
    fi
else
    echo "✅ Twilio trunk created: $TRUNK_ID"
fi

# Create Dispatch Rule using API
echo "📋 Creating Twilio Dispatch Rule via API..."

DISPATCH_JSON='{
  "dispatch_rule": {
    "rule": {
      "dispatchRuleIndividual": {
        "roomPrefix": "twilio-call-"
      }
    },
    "name": "Twilio Dispatch Rule",
    "trunk_ids": ["'$TRUNK_ID'"],
    "hide_phone_number": false,
    "room_config": {
      "agents": [{
        "agent_name": "twilio-inbound-agent",
        "metadata": "Twilio call routing metadata"
      }]
    }
  }
}'

DISPATCH_RESPONSE=$(curl -s -X POST "$HTTP_URL/sip/create_dispatch_rule" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DISPATCH_JSON")

echo "Dispatch rule creation response: $DISPATCH_RESPONSE"

RULE_ID=$(echo "$DISPATCH_RESPONSE" | jq -r '.sip_dispatch_rule_id // .dispatch_rule.sip_dispatch_rule_id // empty')

if [ -z "$RULE_ID" ] || [ "$RULE_ID" = "null" ]; then
    echo "⚠️ Dispatch rule creation may have failed, checking existing rules..."
    
    # Try to find existing rule
    EXISTING_RULES=$(curl -s -X GET "$HTTP_URL/sip/list_dispatch_rule" \
        -H "Authorization: Bearer $TOKEN")
    
    RULE_ID=$(echo "$EXISTING_RULES" | jq -r '.[] | select(.name == "Twilio Dispatch Rule") | .sip_dispatch_rule_id' | head -1)
    
    if [ ! -z "$RULE_ID" ] && [ "$RULE_ID" != "null" ]; then
        echo "✅ Found existing dispatch rule: $RULE_ID"
    else
        echo "❌ Failed to create or find dispatch rule"
        echo "Response: $DISPATCH_RESPONSE"
        exit 1
    fi
else
    echo "✅ Dispatch rule created: $RULE_ID"
fi

# Verify configuration
echo ""
echo "🎯 Configuration Summary:"
echo "========================"
echo "✅ Trunk ID: $TRUNK_ID"
echo "✅ Rule ID: $RULE_ID"
echo "✅ Twilio Number: +13074606119"
echo "✅ Room Prefix: twilio-call-"
echo "✅ Agent Name: twilio-inbound-agent"
echo ""

# List all trunks and rules for verification
echo "📞 Verifying trunks:"
curl -s -X GET "$HTTP_URL/sip/list_trunk" \
    -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "📋 Verifying dispatch rules:"
curl -s -X GET "$HTTP_URL/sip/list_dispatch_rule" \
    -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "🎉 SIP Configuration completed successfully!"
echo ""
echo "📝 Important: Configure Twilio Webhook"
echo "1. Go to Twilio Console > Phone Numbers"
echo "2. Select your number: +13074606119"
echo "3. Set webhook URL to: http://YOUR_PUBLIC_IP:5060"
echo "4. Ensure HTTP method is set to POST"
echo "5. Test by calling +13074606119"

# Save configuration for reference
cat > /tmp/sip-config.json << EOF
{
  "trunk_id": "$TRUNK_ID",
  "rule_id": "$RULE_ID",
  "twilio_number": "+13074606119",
  "configured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo ""
echo "💾 Configuration saved to /tmp/sip-config.json"