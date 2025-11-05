#!/bin/bash

# LiveKit SIP Trunk and Dispatch Setup Script
# This script creates SIP trunk and dispatch rules using lk CLI

# Load environment variables
source .env

# Check if lk CLI is installed
if ! command -v lk &> /dev/null; then
    echo "LiveKit CLI not found. Installing..."
    curl -sSL https://get.livekit.io/cli | bash
fi

# Configure lk CLI with your LiveKit server
lk cloud add myserver --api-key $LIVEKIT_API_KEY --api-secret $LIVEKIT_API_SECRET --url $LIVEKIT_URL

echo "Creating SIP Trunk..."

# Create SIP Trunk
# Replace with your SIP provider details
lk sip trunk create \
  --name "MyTrunk" \
  --address "sip:provider.example.com:5060" \
  --username "your-sip-username" \
  --password "your-sip-password" \
  --outbound-number "+1234567890"

echo "SIP Trunk created successfully!"

# Get the trunk ID (you'll need to replace this with actual trunk ID from the output)
TRUNK_ID="your-trunk-id-here"

echo "Creating SIP Dispatch Rule..."

# Create dispatch rule to route incoming calls
lk sip dispatch create \
  --trunk-id "$TRUNK_ID" \
  --rule-type "individual" \
  --room-prefix "call-" \
  --pin ""

echo "SIP Dispatch Rule created successfully!"

echo "Setup complete! Your SIP service is now configured."
