# Setup Inbound SIP Trunk and Dispatch Rules (PowerShell)
# This script configures LiveKit to accept incoming SIP calls

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "LiveKit SIP Inbound Call Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Load environment variables from .env
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

Write-Host "Step 1: Creating SIP Trunk for Inbound Calls" -ForegroundColor Yellow
Write-Host "---------------------------------------------"

# Create a generic inbound trunk
$trunkOutput = docker exec livekit-cli lk sip trunk create `
  --name "Inbound-Trunk" `
  --inbound-addresses-regex ".*" `
  --inbound-numbers-regex ".*" `
  -o json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create trunk" -ForegroundColor Red
    Write-Host $trunkOutput
    exit 1
}

# Extract trunk ID from JSON output
$trunkId = ($trunkOutput | ConvertFrom-Json).sip_trunk_id

if ([string]::IsNullOrEmpty($trunkId)) {
    Write-Host "⚠️  Could not extract trunk ID, attempting to list existing trunks..." -ForegroundColor Yellow
    docker exec livekit-cli lk sip trunk list
    Write-Host ""
    Write-Host "Please manually copy the trunk ID from above and run:" -ForegroundColor Yellow
    Write-Host '  docker exec livekit-cli lk sip dispatch create --trunk-id <TRUNK_ID> --name default-inbound --rule-type individual --room-prefix sip-call-'
    exit 1
}

Write-Host "✅ Trunk created: $trunkId" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Creating Default Dispatch Rule" -ForegroundColor Yellow
Write-Host "----------------------------------------"

# Create dispatch rule
docker exec livekit-cli lk sip dispatch create `
  --trunk-id $trunkId `
  --name "default-inbound" `
  --rule-type "individual" `
  --room-prefix "sip-call-" `
  --pin ""

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dispatch rule created successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create dispatch rule" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Verification" -ForegroundColor Yellow
Write-Host "---------------------"
Write-Host "Listing all SIP trunks:"
docker exec livekit-cli lk sip trunk list
Write-Host ""
Write-Host "Listing all dispatch rules:"
docker exec livekit-cli lk sip dispatch list
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✅ SIP Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Incoming calls will now be accepted"
Write-Host "2. Each call creates a room: sip-call-<phone-number>"
Write-Host "3. Monitor with: docker logs -f livekit-sip"
Write-Host "4. Test by calling your SIP number"
Write-Host ""
Write-Host "To join the call from a web client, generate a token:" -ForegroundColor Yellow
Write-Host '  docker exec livekit-cli lk token create --room sip-call-<number> --identity web-user --join'
Write-Host ""
