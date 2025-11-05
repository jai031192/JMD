# LiveKit SIP Trunk and Dispatch Setup Script (PowerShell)
# This script creates SIP trunk and dispatch rules using lk CLI

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$LIVEKIT_URL = $env:LIVEKIT_URL
$LIVEKIT_API_KEY = $env:LIVEKIT_API_KEY
$LIVEKIT_API_SECRET = $env:LIVEKIT_API_SECRET

# Check if lk CLI is installed
if (-not (Get-Command lk -ErrorAction SilentlyContinue)) {
    Write-Host "LiveKit CLI not found. Please install from: https://github.com/livekit/livekit-cli/releases"
    Write-Host "Download the Windows binary and add it to your PATH"
    exit 1
}

# Configure lk CLI with your LiveKit server
Write-Host "Configuring LiveKit CLI..."
lk cloud add myserver --api-key $LIVEKIT_API_KEY --api-secret $LIVEKIT_API_SECRET --url $LIVEKIT_URL

Write-Host "Creating SIP Trunk..."

# Create SIP Trunk
# Replace with your SIP provider details
lk sip trunk create `
  --name "MyTrunk" `
  --address "sip:provider.example.com:5060" `
  --username "your-sip-username" `
  --password "your-sip-password" `
  --outbound-number "+1234567890"

Write-Host "SIP Trunk created successfully!"

# Get the trunk ID (you'll need to replace this with actual trunk ID from the output)
$TRUNK_ID = "your-trunk-id-here"

Write-Host "Creating SIP Dispatch Rule..."

# Create dispatch rule to route incoming calls
lk sip dispatch create `
  --trunk-id "$TRUNK_ID" `
  --rule-type "individual" `
  --room-prefix "call-" `
  --pin ""

Write-Host "SIP Dispatch Rule created successfully!"
Write-Host "Setup complete! Your SIP service is now configured."
