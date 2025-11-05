# LiveKit CLI Quick Reference

## 🚀 Starting the CLI Container

```powershell
# Start CLI container
docker-compose --profile tools up -d livekit-cli

# Check status
docker-compose ps livekit-cli

# View logs
docker-compose logs -f livekit-cli
```

## 📋 Using the CLI

### Option 1: Helper Script (Recommended)
```powershell
# Windows
.\lk.ps1 <command>

# Linux
./lk.sh <command>

# Examples
.\lk.ps1 sip trunk list
.\lk.ps1 room list
.\lk.ps1 token create --join --room test --identity user1
```

### Option 2: Direct Docker Exec
```powershell
docker exec -it livekit-cli lk <command>
```

### Option 3: Interactive Shell
```powershell
docker exec -it livekit-cli sh
# Then run: lk <command>
```

## 🎯 Common Commands

### SIP Trunk Management
```powershell
# List all trunks
.\lk.ps1 sip trunk list

# Create trunk
.\lk.ps1 sip trunk create \
  --name "MyTrunk" \
  --address "sip:provider.example.com:5060" \
  --username "your-username" \
  --password "your-password" \
  --outbound-number "+1234567890"

# Get trunk details
.\lk.ps1 sip trunk get --id <trunk_id>

# Delete trunk
.\lk.ps1 sip trunk delete --id <trunk_id>
```

### SIP Dispatch Rules
```powershell
# List dispatch rules
.\lk.ps1 sip dispatch list

# Create dispatch rule
.\lk.ps1 sip dispatch create \
  --trunk-id <trunk_id> \
  --name "my-dispatch" \
  --rule-type "individual" \
  --room-prefix "call-" \
  --pin ""

# Delete dispatch rule
.\lk.ps1 sip dispatch delete --id <dispatch_id>
```

### Room Management
```powershell
# List all rooms
.\lk.ps1 room list

# Create room
.\lk.ps1 room create --name "test-room"

# Get room details
.\lk.ps1 room get --room "test-room"

# Delete room
.\lk.ps1 room delete --room "test-room"

# List participants in room
.\lk.ps1 room participants --room "test-room"

# Remove participant
.\lk.ps1 room remove-participant --room "test-room" --identity "user1"
```

### Token Generation
```powershell
# Create join token
.\lk.ps1 token create \
  --join \
  --room "test-room" \
  --identity "user1" \
  --valid-for "24h"

# Create token with admin permissions
.\lk.ps1 token create \
  --join \
  --room "test-room" \
  --identity "admin" \
  --valid-for "24h" \
  --can-publish \
  --can-subscribe \
  --can-publish-data

# Create token with recorder permissions
.\lk.ps1 token create \
  --join \
  --room "test-room" \
  --identity "recorder" \
  --valid-for "24h" \
  --recorder
```

### Egress (Recording/Streaming)
```powershell
# List egress sessions
.\lk.ps1 egress list

# Start room composite recording
.\lk.ps1 egress start-room-composite \
  --room "test-room" \
  --file "recording.mp4"

# Start track recording
.\lk.ps1 egress start-track \
  --track-id <track_id> \
  --file "track.mp4"

# Stop egress
.\lk.ps1 egress stop --id <egress_id>
```

### Ingress (RTMP/WHIP Input)
```powershell
# List ingress sessions
.\lk.ps1 ingress list

# Create RTMP ingress
.\lk.ps1 ingress create \
  --name "my-stream" \
  --room "test-room" \
  --type rtmp

# Create WHIP ingress
.\lk.ps1 ingress create \
  --name "my-whip-stream" \
  --room "test-room" \
  --type whip

# Delete ingress
.\lk.ps1 ingress delete --id <ingress_id>
```

## 📝 Pre-made Scripts

All scripts are in the `cli-scripts/` directory:

### 1. List Everything
```powershell
.\lk.ps1 /scripts/list-all.sh
```

### 2. Create SIP Trunk
```powershell
.\lk.ps1 /scripts/create-trunk.sh \
  "MyTrunk" \
  "sip:provider.com:5060" \
  "username" \
  "password" \
  "+1234567890"
```

### 3. Create Dispatch Rule
```powershell
# First get trunk ID
.\lk.ps1 sip trunk list

# Then create dispatch
.\lk.ps1 /scripts/create-dispatch.sh \
  "TRUNK_ID_HERE" \
  "my-dispatch" \
  "call-"
```

### 4. Delete SIP Trunk
```powershell
.\lk.ps1 /scripts/delete-trunk.sh "TRUNK_ID_HERE"
```

### 5. Create Test Token
```powershell
.\lk.ps1 /scripts/create-token.sh "test-room" "test-user"
```

## 🔄 Environment Variables

The CLI container uses these environment variables from `.env`:
- `LIVEKIT_URL` - Your LiveKit server WebSocket URL
- `LIVEKIT_API_KEY` - Your API key
- `LIVEKIT_API_SECRET` - Your API secret

## 🛠️ Troubleshooting

### CLI container not running
```powershell
# Start it
docker-compose --profile tools up -d livekit-cli

# Check logs
docker-compose logs livekit-cli
```

### Connection errors
```powershell
# Verify environment variables
docker exec livekit-cli env | grep LIVEKIT

# Test connection
docker exec livekit-cli lk room list
```

### Script permission errors (Linux)
```bash
# Make scripts executable
chmod +x cli-scripts/*.sh
chmod +x lk.sh
```

## 📚 More Information

Full LiveKit CLI documentation:
https://docs.livekit.io/cli/

## 💡 Tips

1. Use `--help` with any command to see all options:
   ```powershell
   .\lk.ps1 sip trunk create --help
   ```

2. Store frequently used commands in separate scripts

3. Use the interactive shell for multiple commands:
   ```powershell
   docker exec -it livekit-cli sh
   ```

4. Check logs if commands fail:
   ```powershell
   docker-compose logs livekit-cli
   ```
