#!/bin/bash
# Bash script to interact with LiveKit CLI container
# Usage: ./lk.sh <command> [args...]

if [ $# -eq 0 ]; then
    echo "LiveKit CLI Helper"
    echo "=================="
    echo ""
    echo "Usage: ./lk.sh <command> [args...]"
    echo ""
    echo "Examples:"
    echo "  ./lk.sh sip trunk list"
    echo "  ./lk.sh sip dispatch list"
    echo "  ./lk.sh room list"
    echo "  ./lk.sh token create --join --room test --identity user1"
    echo ""
    echo "Or run scripts:"
    echo "  ./lk.sh /scripts/list-all.sh"
    echo "  ./lk.sh /scripts/create-trunk.sh MyTrunk sip:provider.com user pass +1234"
    echo ""
    exit 0
fi

# Check if livekit-cli container is running
if ! docker ps --filter "name=livekit-cli" --format "{{.Names}}" | grep -q "livekit-cli"; then
    echo "❌ Error: livekit-cli container is not running"
    echo "Start it with: docker-compose --profile tools up -d livekit-cli"
    exit 1
fi

# Execute command in container
docker exec -it livekit-cli lk "$@"
