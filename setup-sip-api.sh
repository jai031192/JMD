#!/bin/bash
# Complete SIP setup using LiveKit API with JSON

set -e

echo "======================================"
echo "LiveKit SIP Setup (API Method)"
echo "======================================"
echo ""

# Step 1: Create trunk
echo "Step 1: Creating SIP Trunk..."
./create-trunk-api.sh

if [ $? -ne 0 ]; then
    echo "❌ Failed at trunk creation"
    exit 1
fi

# Get trunk ID
TRUNK_ID=$(cat .trunk_id)
echo ""
echo "Trunk ID: $TRUNK_ID"
echo ""

# Step 2: Create dispatch rule
echo "Step 2: Creating Dispatch Rule..."
./create-dispatch-api.sh "$TRUNK_ID"

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✅ SIP Setup Complete!"
    echo "======================================"
    echo ""
    echo "Test by calling: 40.81.229.194:5060"
    echo "Monitor logs: docker logs -f livekit-sip"
else
    echo "❌ Failed at dispatch rule creation"
    exit 1
fi
