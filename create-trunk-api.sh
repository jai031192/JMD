#!/bin/bash
# Create SIP Trunk using LiveKit API (JSON method)

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

LIVEKIT_URL="${LIVEKIT_URL:-wss://livekit-socket.immodesta.com}"
API_KEY="${LIVEKIT_API_KEY}"
API_SECRET="${LIVEKIT_API_SECRET}"

# Convert wss:// to https://
HTTP_URL=$(echo "$LIVEKIT_URL" | sed 's/wss:/https:/')

# Generate JWT token for authentication
TOKEN=$(docker exec livekit-cli lk token create --create-sip-trunk --list-sip-trunk)

# Trunk configuration JSON (Updated for Twilio testing)
TRUNK_JSON='{
  "trunk": {
    "name": "Twilio Test Trunk",
    "numbers": [
      "+13074606119"
    ],
    "krispEnabled": true
  }
}'

echo "Creating SIP Trunk via API..."
echo "URL: $HTTP_URL/sip/create_trunk"
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
    echo "❌ Failed to create trunk"
    exit 1
fi

echo ""
echo "✅ Trunk created: $TRUNK_ID"
echo "$TRUNK_ID" > .trunk_id

# List trunks to verify
echo ""
echo "Verifying - Listing all trunks:"
docker exec livekit-cli lk sip trunk list
