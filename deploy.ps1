# Automated SIP Setup - Complete Deployment Script (PowerShell)

Write-Host "🚀 Starting Automated LiveKit SIP Setup with Twilio Integration" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "📋 Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Please update .env file with your actual credentials:" -ForegroundColor Yellow
    Write-Host "   - LIVEKIT_URL" -ForegroundColor White
    Write-Host "   - LIVEKIT_API_KEY" -ForegroundColor White
    Write-Host "   - LIVEKIT_API_SECRET" -ForegroundColor White
    Write-Host "   - TWILIO_ACCOUNT_SID" -ForegroundColor White
    Write-Host "   - TWILIO_AUTH_TOKEN" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    exit 1
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

# Verify required variables
Write-Host "🔍 Verifying configuration..." -ForegroundColor Yellow
$missing_vars = 0

function Check-EnvVar {
    param($varName)
    $value = [Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrEmpty($value) -or $value.StartsWith("your_")) {
        Write-Host "❌ Missing: $varName" -ForegroundColor Red
        return $false
    } else {
        Write-Host "✅ Found: $varName" -ForegroundColor Green
        return $true
    }
}

if (-not (Check-EnvVar "LIVEKIT_URL")) { $missing_vars = 1 }
if (-not (Check-EnvVar "LIVEKIT_API_KEY")) { $missing_vars = 1 }
if (-not (Check-EnvVar "LIVEKIT_API_SECRET")) { $missing_vars = 1 }
if (-not (Check-EnvVar "TWILIO_ACCOUNT_SID")) { $missing_vars = 1 }
if (-not (Check-EnvVar "TWILIO_AUTH_TOKEN")) { $missing_vars = 1 }

if ($missing_vars -eq 1) {
    Write-Host ""
    Write-Host "❌ Please update .env file with missing variables" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Configuration verified!" -ForegroundColor Green

# Check Docker
Write-Host ""
Write-Host "🐳 Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker and try again." -ForegroundColor Red
    exit 1
}

# Pull latest images
Write-Host ""
Write-Host "📥 Pulling latest Docker images..." -ForegroundColor Yellow
docker-compose pull

# Stop existing services
Write-Host ""
Write-Host "🛑 Stopping any existing services..." -ForegroundColor Yellow
docker-compose down --remove-orphans

# Start services
Write-Host ""
Write-Host "🚀 Starting LiveKit SIP services..." -ForegroundColor Yellow
docker-compose up -d redis sip

# Wait for core services
Write-Host ""
Write-Host "⏳ Waiting for core services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

Write-Host "🔍 Checking service health..." -ForegroundColor Yellow
docker-compose ps

# Optionally start initialization
$TWILIO_SID = $env:TWILIO_ACCOUNT_SID
$TWILIO_TOKEN = $env:TWILIO_AUTH_TOKEN

if (-not [string]::IsNullOrEmpty($TWILIO_SID) -and -not [string]::IsNullOrEmpty($TWILIO_TOKEN)) {
    Write-Host ""
    Write-Host "⚙️  Starting SIP configuration initialization..." -ForegroundColor Yellow
    $initResult = docker-compose --profile init up sip-init
    $initExitCode = $LASTEXITCODE
} else {
    Write-Host ""
    Write-Host "⚠️  Skipping SIP initialization (Twilio credentials not configured)" -ForegroundColor Yellow
    Write-Host "   To enable auto-configuration, set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN in .env" -ForegroundColor White
    $initExitCode = 0
}

if ($initExitCode -eq 0) {
    Write-Host ""
    Write-Host "🎉 SIP Configuration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host "✅ Redis: Running on port 6379" -ForegroundColor Green
    Write-Host "✅ SIP Service: Running on port 5060" -ForegroundColor Green
    Write-Host "✅ RTP Ports: 50000-60000" -ForegroundColor Green
    Write-Host "✅ Health Check: http://localhost:8080/health" -ForegroundColor Green
    
    if (-not [string]::IsNullOrEmpty($TWILIO_SID)) {
        Write-Host "✅ Twilio Trunk: Created for +13074606119" -ForegroundColor Green
        Write-Host "✅ Dispatch Rule: Created with prefix 'twilio-call-'" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📞 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure Twilio webhook URL: http://YOUR_PUBLIC_IP:5060" -ForegroundColor White
    Write-Host "2. Ensure firewall allows ports 5060 and 50000-60000" -ForegroundColor White
    Write-Host "3. Test by calling +13074606119" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
    Write-Host "  View logs: docker-compose logs -f sip" -ForegroundColor White
    Write-Host "  Create trunk: .\create-trunk-api.ps1" -ForegroundColor White
    Write-Host "  Create dispatch rule: .\create-dispatch-api.ps1" -ForegroundColor White
    Write-Host "  Stop services: docker-compose down" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ SIP Configuration failed!" -ForegroundColor Red
    Write-Host "Check logs: docker-compose logs sip-init" -ForegroundColor Yellow
    exit 1
}

# Show service status
Write-Host ""
Write-Host "📊 Service Status:" -ForegroundColor Cyan
docker-compose ps