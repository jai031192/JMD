#!/bin/sh
# Create SIP Trunk Script
# Usage: ./create-trunk.sh <trunk_name> <sip_address> <username> <password> <outbound_number>

TRUNK_NAME=${1:-"MyTrunk"}
SIP_ADDRESS=${2:-"sip:provider.example.com:5060"}
USERNAME=${3:-"your-username"}
PASSWORD=${4:-"your-password"}
OUTBOUND_NUMBER=${5:-"+1234567890"}

echo "Creating SIP Trunk: $TRUNK_NAME"
echo "SIP Address: $SIP_ADDRESS"
echo "Username: $USERNAME"
echo "Outbound Number: $OUTBOUND_NUMBER"

lk sip trunk create \
  --name "$TRUNK_NAME" \
  --address "$SIP_ADDRESS" \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --outbound-number "$OUTBOUND_NUMBER"

if [ $? -eq 0 ]; then
  echo "✅ SIP Trunk created successfully!"
  echo "Listing all trunks:"
  lk sip trunk list
else
  echo "❌ Failed to create SIP trunk"
  exit 1
fi
