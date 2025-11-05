#!/bin/sh
# Delete SIP Trunk
# Usage: ./delete-trunk.sh <trunk_id>

TRUNK_ID=${1}

if [ -z "$TRUNK_ID" ]; then
  echo "❌ Error: Trunk ID is required"
  echo "Usage: ./delete-trunk.sh <trunk_id>"
  echo ""
  echo "Available trunks:"
  lk sip trunk list
  exit 1
fi

echo "Deleting SIP Trunk: $TRUNK_ID"

lk sip trunk delete --id "$TRUNK_ID"

if [ $? -eq 0 ]; then
  echo "✅ SIP Trunk deleted successfully!"
else
  echo "❌ Failed to delete SIP trunk"
  exit 1
fi
