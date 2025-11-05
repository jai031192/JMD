#!/bin/sh
# List all SIP trunks

echo "📋 SIP Trunks:"
echo "=============="
lk sip trunk list

echo ""
echo "📋 SIP Dispatch Rules:"
echo "======================"
lk sip dispatch list

echo ""
echo "📋 Active Rooms:"
echo "================"
lk room list
