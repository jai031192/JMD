#!/bin/bash
# Create SIP Dispatch Rule using LiveKit API (JSON method)

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

LIVEKIT_URL="${LIVEKIT_URL:-wss://livekit-socket.immodesta.com}"
HTTP_URL=$(echo "$LIVEKIT_URL" | sed 's/wss:/https:/')

# Get trunk ID from previous step or parameter
TRUNK_ID="${1}"
if [ -z "$TRUNK_ID" ] && [ -f .trunk_id ]; then
    TRUNK_ID=$(cat .trunk_id)
fi

if [ -z "$TRUNK_ID" ]; then
    echo "❌ Error: Trunk ID required"
    echo "Usage: ./create-dispatch-api.sh <TRUNK_ID>"
    echo ""
    echo "Or run create-trunk-api.sh first to auto-save trunk ID"
    exit 1
fi

# Generate JWT token
TOKEN=$(docker exec livekit-cli lk token create --create-sip-dispatch --list-sip-dispatch)

# Dispatch rule configuration JSON
DISPATCH_JSON='{
  "dispatch_rule": {
    "rule": {
      "dispatchRuleIndividual": {
        "roomPrefix": "sip-call-"
      }
    },
    "name": "default-inbound",
    "trunk_ids": ["'$TRUNK_ID'"]
  }
}'

echo "Creating Dispatch Rule via API..."
echo "URL: $HTTP_URL/sip/create_dispatch_rule"
echo "Trunk ID: $TRUNK_ID"
echo "JSON: $DISPATCH_JSON"
echo ""

# Create dispatch rule via API
RESPONSE=$(curl -s -X POST "$HTTP_URL/sip/create_dispatch_rule" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DISPATCH_JSON")

echo "Response:"
echo "$RESPONSE" | jq .

# Extract dispatch rule ID
RULE_ID=$(echo "$RESPONSE" | jq -r '.sip_dispatch_rule_id // .dispatch_rule.sip_dispatch_rule_id')

if [ -z "$RULE_ID" ] || [ "$RULE_ID" = "null" ]; then
    echo "❌ Failed to create dispatch rule"
    exit 1
fi

echo ""
echo "✅ Dispatch rule created: $RULE_ID"

# List dispatch rules to verify
echo ""
echo "Verifying - Listing all dispatch rules:"
docker exec livekit-cli lk sip dispatch list
