# Create SIP Dispatch Rule using LiveKit API (JSON method) - PowerShell

param(
    [string]$TrunkId
)

# Load environment variables
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$LIVEKIT_URL = $env:LIVEKIT_URL -replace 'wss:', 'https:'

# Get trunk ID
if ([string]::IsNullOrEmpty($TrunkId) -and (Test-Path .trunk_id)) {
    $TrunkId = Get-Content .trunk_id
}

if ([string]::IsNullOrEmpty($TrunkId)) {
    Write-Host "❌ Error: Trunk ID required" -ForegroundColor Red
    Write-Host "Usage: .\create-dispatch-api.ps1 -TrunkId <ID>"
    exit 1
}

# Generate JWT token
$TOKEN = docker exec livekit-cli lk token create --create-sip-dispatch --list-sip-dispatch

# Dispatch rule JSON (Updated for Twilio integration)
$DISPATCH_JSON = @{
    dispatch_rule = @{
        rule = @{
            dispatchRuleIndividual = @{
                roomPrefix = "twilio-call-"
            }
        }
        name = "Twilio Dispatch Rule"
        roomConfig = @{
            agents = @(
                @{
                    agentName = "twilio-inbound-agent"
                    metadata = "Twilio call routing metadata"
                }
            )
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating Dispatch Rule via API..." -ForegroundColor Yellow
Write-Host "URL: $LIVEKIT_URL/sip/create_dispatch_rule"
Write-Host "Trunk ID: $TrunkId"
Write-Host ""

# Create dispatch rule
$RESPONSE = Invoke-RestMethod -Uri "$LIVEKIT_URL/sip/create_dispatch_rule" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body $DISPATCH_JSON

Write-Host "Response:" -ForegroundColor Cyan
$RESPONSE | ConvertTo-Json -Depth 10

# Extract dispatch rule ID
$RULE_ID = $RESPONSE.sip_dispatch_rule_id
if ([string]::IsNullOrEmpty($RULE_ID)) {
    $RULE_ID = $RESPONSE.dispatch_rule.sip_dispatch_rule_id
}

if ([string]::IsNullOrEmpty($RULE_ID)) {
    Write-Host "❌ Failed to create dispatch rule" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Dispatch rule created: $RULE_ID" -ForegroundColor Green

# List dispatch rules
Write-Host ""
Write-Host "Verifying - Listing all dispatch rules:" -ForegroundColor Yellow
docker exec livekit-cli lk sip dispatch list
