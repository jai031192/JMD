# Create SIP Trunk for Twilio Integration - PowerShell

# Load environment variables
if (Test-Path .env.twilio) {
    Get-Content .env.twilio | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}
elseif (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$LIVEKIT_URL = ($env:LIVEKIT_URL -replace 'wss:', 'https:') ?? "https://livekit-socket.immodesta.com"
$TWILIO_PHONE = $env:TWILIO_PHONE_NUMBER ?? "+13074606119"
$TWILIO_SID = $env:TWILIO_ACCOUNT_SID
$TWILIO_TOKEN = $env:TWILIO_AUTH_TOKEN

if ([string]::IsNullOrEmpty($TWILIO_SID) -or [string]::IsNullOrEmpty($TWILIO_TOKEN)) {
    Write-Host "❌ Error: Twilio credentials not found" -ForegroundColor Red
    Write-Host "Please update .env.twilio with your Twilio Account SID and Auth Token" -ForegroundColor Yellow
    exit 1
}

# Generate JWT token
$TOKEN = docker exec livekit-cli lk token create --create-sip-trunk --list-sip-trunk

# Twilio SIP Trunk configuration
$TRUNK_JSON = @{
    trunk = @{
        name = "Twilio Test Trunk"
        numbers = @($TWILIO_PHONE)
        inbound_addresses = @("54.172.60.0/23", "54.244.51.0/24", "54.171.127.192/27")
        outbound_address = "sip.twilio.com"
        outbound_number = $TWILIO_PHONE
        inbound_username = ""
        inbound_password = ""
        outbound_username = $TWILIO_SID
        outbound_password = $TWILIO_TOKEN
        krispEnabled = $true
    }
} | ConvertTo-Json -Depth 10

Write-Host "Creating Twilio SIP Trunk via API..." -ForegroundColor Yellow
Write-Host "URL: $LIVEKIT_URL/sip/create_trunk"
Write-Host "Twilio Phone: $TWILIO_PHONE"
Write-Host ""

# Create trunk via API
try {
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
        Write-Host "❌ Failed to create Twilio trunk" -ForegroundColor Red
        Write-Host "Make sure your Twilio credentials are correct in .env.twilio" -ForegroundColor Yellow
        exit 1
    }

    Write-Host ""
    Write-Host "✅ Twilio Trunk created: $TRUNK_ID" -ForegroundColor Green
    $TRUNK_ID | Out-File -FilePath .trunk_id -Encoding ASCII

    # Save Twilio configuration
    "TWILIO_TRUNK_ID=$TRUNK_ID" | Out-File -FilePath .env.twilio -Append -Encoding ASCII

    # List trunks
    Write-Host ""
    Write-Host "Verifying - Listing all trunks:" -ForegroundColor Yellow
    docker exec livekit-cli lk sip trunk list

    Write-Host ""
    Write-Host "📞 Twilio Configuration Notes:" -ForegroundColor Cyan
    Write-Host "1. Configure your Twilio phone number webhook URL to point to your LiveKit SIP endpoint" -ForegroundColor White
    Write-Host "2. Webhook URL should be: http://YOUR_PUBLIC_IP:5060" -ForegroundColor White
    Write-Host "3. Make sure ports 5060 (SIP) and 10000-10100 (RTP) are open in your firewall" -ForegroundColor White
    Write-Host "4. Your Twilio number $TWILIO_PHONE is now configured for inbound calls" -ForegroundColor White
}
catch {
    Write-Host "❌ Error creating Twilio trunk: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}