# PowerShell script to interact with LiveKit CLI container
# Usage: .\lk.ps1 <command> [args...]

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$command = $Arguments -join " "

if ([string]::IsNullOrWhiteSpace($command)) {
    Write-Host "LiveKit CLI Helper"
    Write-Host "==================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\lk.ps1 <command> [args...]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\lk.ps1 sip trunk list"
    Write-Host "  .\lk.ps1 sip dispatch list"
    Write-Host "  .\lk.ps1 room list"
    Write-Host "  .\lk.ps1 token create --join --room test --identity user1"
    Write-Host ""
    Write-Host "Or run scripts:"
    Write-Host "  .\lk.ps1 /scripts/list-all.sh"
    Write-Host "  .\lk.ps1 /scripts/create-trunk.sh MyTrunk sip:provider.com user pass +1234"
    Write-Host ""
    exit 0
}

# Check if livekit-cli container is running
$running = docker ps --filter "name=livekit-cli" --format "{{.Names}}"
if ($running -ne "livekit-cli") {
    Write-Host "❌ Error: livekit-cli container is not running" -ForegroundColor Red
    Write-Host "Start it with: docker-compose --profile tools up -d livekit-cli" -ForegroundColor Yellow
    exit 1
}

# Execute command in container
docker exec -it livekit-cli lk $command
