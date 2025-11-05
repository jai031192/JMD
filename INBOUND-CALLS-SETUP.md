# Setting Up Inbound SIP Calls

## Problem
Your SIP service is running correctly but rejecting incoming calls with `"reason": "flood"`. This happens because LiveKit SIP needs **dispatch rules** to know how to handle incoming calls.

## Quick Fix

### On Linux Server (Azure VM):
```bash
cd ~/jmd/JMD
docker-compose --profile tools up -d livekit-cli
chmod +x setup-inbound-sip.sh
./setup-inbound-sip.sh
```

### On Windows (Local):
```powershell
cd "C:\Users\JaivardhanSinghRatho\New folder (2)"
docker-compose --profile tools up -d livekit-cli
.\setup-inbound-sip.ps1
```

## What This Does

1. **Creates SIP Trunk**: A trunk that accepts calls from any IP address
2. **Creates Dispatch Rule**: Routes each incoming call to a unique LiveKit room with prefix `sip-call-`

## After Setup

### Test Incoming Calls
Make a call to your server's IP: `40.81.229.194:5060`

The call will create a room named: `sip-call-<caller-number>`

### Monitor Calls
```bash
docker logs -f livekit-sip
```

You should see:
```
processing invite
Creating room: sip-call-+1234567890
```

Instead of:
```
reason: "flood"  ❌
```

### Join Call from Web Browser

1. Generate a join token for the room:
```bash
docker exec livekit-cli lk token create \
  --room sip-call-+1234567890 \
  --identity web-user \
  --join
```

2. Use the token with LiveKit React or other web client to join the call

## Manual Configuration (Alternative)

If the script fails, run commands manually:

```bash
# Start CLI container
docker-compose --profile tools up -d livekit-cli

# Create trunk
docker exec livekit-cli lk sip trunk create \
  --name "Inbound-Trunk" \
  --inbound-addresses-regex ".*" \
  --inbound-numbers-regex ".*"

# Note the trunk ID from output, then create dispatch rule
docker exec livekit-cli lk sip dispatch create \
  --trunk-id <TRUNK_ID_FROM_ABOVE> \
  --name "default-inbound" \
  --rule-type "individual" \
  --room-prefix "sip-call-"
```

## Verify Configuration

```bash
# List all trunks
docker exec livekit-cli lk sip trunk list

# List all dispatch rules
docker exec livekit-cli lk sip dispatch list
```

## Understanding the Logs

### Before Fix (Current State):
```json
"status": 486, "reason": "flood"
```
- Status 486 = Busy Here (call rejected)
- Reason "flood" = No dispatch rule found

### After Fix:
```json
"status": 200, "room": "sip-call-+1234567890"
```
- Status 200 = OK (call accepted)
- Room created and media connected

## Troubleshooting

### Issue: "trunk not found"
**Solution**: List trunks and verify ID
```bash
docker exec livekit-cli lk sip trunk list
```

### Issue: "unauthorized"
**Solution**: Check .env credentials
```bash
cat .env | grep LIVEKIT
```

### Issue: Calls still rejected
**Solution**: Verify dispatch rule exists
```bash
docker exec livekit-cli lk sip dispatch list
```

## Call Flow

```
Incoming SIP Call (from 64.95.96.70)
         ↓
   SIP Service (port 5060)
         ↓
   Check Dispatch Rules ← ⚠️ YOU ARE HERE (no rules = flood)
         ↓
   Create Room (sip-call-+1234567890)
         ↓
   Connect Media (RTP ports 10000-10100)
         ↓
   Call Active ✅
```

## Next Steps

1. Run setup script to create trunk and dispatch rule
2. Test by making a call to your server
3. Monitor logs to see room creation
4. Join the room from a web client using generated token
5. Implement your voice agent logic to interact with the call

## Security Notes

- Current setup accepts calls from **any IP address** (good for testing)
- For production, restrict to specific providers:
  ```bash
  --inbound-addresses-regex "^(64\.95\.96\.70|216\.126\.227\.248)$"
  ```
- Add authentication with trunk username/password if required by your provider
