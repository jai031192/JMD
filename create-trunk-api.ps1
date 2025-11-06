# Create SIP Trunk using LiveKit API (JSON method) - PowerShell

# Load environment variables
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$LIVEKIT_URL = $env:LIVEKIT_URL -replace 'wss:', 'https:'

# Generate JWT token
$TOKEN = docker exec livekit-cli lk token create --create-sip-trunk --list-sip-trunk

# Trunk configuration JSON (Updated for Twilio testing)
$TRUNK_JSON = @{
    trunk = @{
        name = "Twilio Test Trunk"
        numbers = @("+13074606119")
        krispEnabled = $true
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating SIP Trunk via API..." -ForegroundColor Yellow
Write-Host "URL: $LIVEKIT_URL/sip/create_trunk"
Write-Host ""

# Create trunk via API
$RESPONSE = Invoke-RestMethod -Uri "$LIVEKIT_URL/sip/create_trunk" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body $TRUNK_JSON

Write-Host "Response:" -ForegroundColor Cyan
$RESPONSE | ConvertTo-Json -Depth 10

# Extract trunk ID
$TRUNK_ID = $RESPONSE.sip_trunk_id
if ([string]::IsNullOrEmpty($TRUNK_ID)) {
    $TRUNK_ID = $RESPONSE.trunk.sip_trunk_id
}

if ([string]::IsNullOrEmpty($TRUNK_ID)) {
    Write-Host "❌ Failed to create trunk" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Trunk created: $TRUNK_ID" -ForegroundColor Green
$TRUNK_ID | Out-File -FilePath .trunk_id -Encoding ASCII

# List trunks
Write-Host ""
Write-Host "Verifying - Listing all trunks:" -ForegroundColor Yellow
docker exec livekit-cli lk sip trunk list
