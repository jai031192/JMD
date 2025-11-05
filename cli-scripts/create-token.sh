#!/bin/sh
# Create a join token for testing
# Usage: ./create-token.sh <room_name> <participant_identity>

ROOM_NAME=${1:-"test-room"}
PARTICIPANT_IDENTITY=${2:-"test-user"}

echo "Creating join token for:"
echo "Room: $ROOM_NAME"
echo "Participant: $PARTICIPANT_IDENTITY"

lk token create \
  --join \
  --room "$ROOM_NAME" \
  --identity "$PARTICIPANT_IDENTITY" \
  --valid-for "24h"

echo ""
echo "✅ Token created! Copy the token above to join the room."
