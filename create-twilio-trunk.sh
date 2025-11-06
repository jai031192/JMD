#!/bin/bash
# Create SIP Trunk for Twilio Integration

set -e

# Load environment variables
if [ -f .env.twilio ]; then
    export $(cat .env.twilio | grep -v '^#' | xargs)
elif [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

LIVEKIT_URL="${LIVEKIT_URL:-wss://livekit-socket.immodesta.com}"
API_KEY="${LIVEKIT_API_KEY}"
API_SECRET="${LIVEKIT_API_SECRET}"
TWILIO_PHONE="${TWILIO_PHONE_NUMBER:-+13074606119}"

# Convert wss:// to https://
HTTP_URL=$(echo "$LIVEKIT_URL" | sed 's/wss:/https:/')

# Generate JWT token for authentication
TOKEN=$(docker exec livekit-cli lk token create --create-sip-trunk --list-sip-trunk)

# Twilio SIP Trunk configuration
TRUNK_JSON='{
  "trunk": {
    "name": "Twilio Test Trunk",
    "numbers": ["'$TWILIO_PHONE'"],
    "inbound_addresses": ["54.172.60.0/23", "54.244.51.0/24", "54.171.127.192/27"],
    "outbound_address": "sip.twilio.com",
    "outbound_number": "'$TWILIO_PHONE'",
    "inbound_username": "",
    "inbound_password": "",
    "outbound_username": "'$TWILIO_ACCOUNT_SID'",
    "outbound_password": "'$TWILIO_AUTH_TOKEN'",
    "krispEnabled": true
  }
}'

echo "Creating Twilio SIP Trunk via API..."
echo "URL: $HTTP_URL/sip/create_trunk"
echo "Twilio Phone: $TWILIO_PHONE"
echo "JSON: $TRUNK_JSON"
echo ""

# Create trunk via API
RESPONSE=$(curl -s -X POST "$HTTP_URL/sip/create_trunk" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$TRUNK_JSON")

echo "Response:"
echo "$RESPONSE" | jq .

# Extract trunk ID
TRUNK_ID=$(echo "$RESPONSE" | jq -r '.sip_trunk_id // .trunk.sip_trunk_id')

if [ -z "$TRUNK_ID" ] || [ "$TRUNK_ID" = "null" ]; then
    echo "❌ Failed to create Twilio trunk"
    echo "Make sure your Twilio credentials are correct in .env.twilio"
    exit 1
fi

echo ""
echo "✅ Twilio Trunk created: $TRUNK_ID"
echo "$TRUNK_ID" > .trunk_id

# Save Twilio configuration
echo "TWILIO_TRUNK_ID=$TRUNK_ID" >> .env.twilio

# List trunks to verify
echo ""
echo "Verifying - Listing all trunks:"
docker exec livekit-cli lk sip trunk list

echo ""
echo "📞 Twilio Configuration Notes:"
echo "1. Configure your Twilio phone number webhook URL to point to your LiveKit SIP endpoint"
echo "2. Webhook URL should be: http://YOUR_PUBLIC_IP:5060"
echo "3. Make sure ports 5060 (SIP) and 10000-10100 (RTP) are open in your firewall"
echo "4. Your Twilio number $TWILIO_PHONE is now configured for inbound calls"