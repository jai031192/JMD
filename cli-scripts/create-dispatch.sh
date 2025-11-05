#!/bin/sh
# Create SIP Dispatch Rule Script
# Usage: ./create-dispatch.sh <trunk_id> <rule_name> <room_prefix>

TRUNK_ID=${1}
RULE_NAME=${2:-"default-dispatch"}
ROOM_PREFIX=${3:-"sip-"}

if [ -z "$TRUNK_ID" ]; then
  echo "❌ Error: Trunk ID is required"
  echo "Usage: ./create-dispatch.sh <trunk_id> [rule_name] [room_prefix]"
  echo ""
  echo "Available trunks:"
  lk sip trunk list
  exit 1
fi

echo "Creating SIP Dispatch Rule: $RULE_NAME"
echo "Trunk ID: $TRUNK_ID"
echo "Room Prefix: $ROOM_PREFIX"

lk sip dispatch create \
  --trunk-id "$TRUNK_ID" \
  --name "$RULE_NAME" \
  --rule-type "individual" \
  --room-prefix "$ROOM_PREFIX" \
  --pin ""

if [ $? -eq 0 ]; then
  echo "✅ SIP Dispatch Rule created successfully!"
  echo "Listing all dispatch rules:"
  lk sip dispatch list
else
  echo "❌ Failed to create dispatch rule"
  exit 1
fi
