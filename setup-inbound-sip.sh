#!/bin/bash
# Setup Inbound SIP Trunk and Dispatch Rules
# This script configures LiveKit to accept incoming SIP calls

set -e

echo "======================================"
echo "LiveKit SIP Inbound Call Setup"
echo "======================================"
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set CLI environment
export LIVEKIT_URL="${LIVEKIT_URL}"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET}"

echo "Step 1: Creating SIP Trunk for Inbound Calls"
echo "---------------------------------------------"

# Create a generic inbound trunk
# This trunk accepts calls from any IP address
TRUNK_JSON=$(docker exec livekit-cli lk sip trunk create \
  --name "Inbound-Trunk" \
  --inbound-addresses-regex ".*" \
  --inbound-numbers-regex ".*" \
  -o json 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Failed to create trunk"
    echo "$TRUNK_JSON"
    exit 1
fi

TRUNK_ID=$(echo "$TRUNK_JSON" | grep -o '"sip_trunk_id":"[^"]*' | cut -d'"' -f4)

if [ -z "$TRUNK_ID" ]; then
    echo "⚠️  Could not extract trunk ID, attempting to list existing trunks..."
    docker exec livekit-cli lk sip trunk list
    echo ""
    echo "Please manually copy the trunk ID from above and run:"
    echo "  docker exec livekit-cli lk sip dispatch create --trunk-id <TRUNK_ID> --name default-inbound --rule-type individual --room-prefix sip-call-"
    exit 1
fi

echo "✅ Trunk created: $TRUNK_ID"
echo ""

echo "Step 2: Creating Default Dispatch Rule"
echo "----------------------------------------"

# Create dispatch rule to route all calls to rooms with prefix "sip-call-"
docker exec livekit-cli lk sip dispatch create \
  --trunk-id "$TRUNK_ID" \
  --name "default-inbound" \
  --rule-type "individual" \
  --room-prefix "sip-call-" \
  --pin ""

if [ $? -eq 0 ]; then
    echo "✅ Dispatch rule created successfully!"
else
    echo "❌ Failed to create dispatch rule"
    exit 1
fi

echo ""
echo "Step 3: Verification"
echo "---------------------"
echo "Listing all SIP trunks:"
docker exec livekit-cli lk sip trunk list
echo ""
echo "Listing all dispatch rules:"
docker exec livekit-cli lk sip dispatch list
echo ""

echo "======================================"
echo "✅ SIP Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Incoming calls will now be accepted"
echo "2. Each call creates a room: sip-call-<phone-number>"
echo "3. Monitor with: docker logs -f livekit-sip"
echo "4. Test by calling your SIP number"
echo ""
echo "To join the call from a web client, generate a token:"
echo "  docker exec livekit-cli lk token create --room sip-call-<number> --identity web-user --join"
echo ""
