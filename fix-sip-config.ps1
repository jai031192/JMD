# Fix SIP Configuration Issues - PowerShell Version

Write-Host "🔧 Fixing SIP Configuration Issues..." -ForegroundColor Yellow

# Backup current files
Write-Host "📋 Creating backups..." -ForegroundColor Cyan
Copy-Item docker-compose.yml docker-compose.yml.backup -ErrorAction SilentlyContinue
Copy-Item sip-config.yaml sip-config.yaml.backup -ErrorAction SilentlyContinue

# Apply fixes to docker-compose.yml
Write-Host "🐳 Fixing Docker Compose configuration..." -ForegroundColor Cyan
@'
version: '3.9'

services:
  # Redis - State management and pub/sub
  redis:
    image: redis:7-alpine
    container_name: livekit-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - livekit-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # SIP Gateway - For telephony integration
  sip:
    image: livekit/sip:latest
    container_name: livekit-sip
    restart: unless-stopped
    ports:
      - "5060:5060/udp"
      - "5060:5060/tcp"
      - "50000-60000:50000-60000/udp"
      - "8080:8080"  # Health check port
    environment:
      - LIVEKIT_URL=${LIVEKIT_URL}
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}
      - SIP_CONFIG_FILE=/sip/config.yaml
    volumes:
      - ./sip-config.yaml:/sip/config.yaml:ro
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - livekit-network
    healthcheck:
      test: ["CMD-SHELL", "wget --spider -q http://localhost:8080/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  # Egress - For recording and streaming (optional)
  egress:
    image: livekit/egress:latest
    container_name: livekit-egress
    restart: unless-stopped
    environment:
      - LIVEKIT_URL=${LIVEKIT_URL}
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    volumes:
      - egress-data:/out
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - livekit-network
    profiles:
      - full

  # Ingress - For RTMP/WHIP input (optional)
  ingress:
    image: livekit/ingress:latest
    container_name: livekit-ingress
    restart: unless-stopped
    ports:
      - "1935:1935"      # RTMP
      - "8081:8080"      # WHIP (changed to avoid conflict)
    environment:
      - LIVEKIT_URL=${LIVEKIT_URL}
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - livekit-network
    profiles:
      - full

  # LiveKit CLI - For management tasks (trunks, dispatch rules, tokens, etc.)
  livekit-cli:
    image: livekit/livekit-cli:latest
    container_name: livekit-cli
    environment:
      - LIVEKIT_URL=${LIVEKIT_URL}
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}
    volumes:
      - ./cli-scripts:/scripts:ro
      - cli-data:/root/.livekit
    networks:
      - livekit-network
    entrypoint: ["/bin/sh"]
    command: ["-c", "while true; do sleep 3600; done"]
    depends_on:
      - redis
    profiles:
      - tools

networks:
  livekit-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  redis-data:
    driver: local
  egress-data:
    driver: local
  cli-data:
    driver: local
'@ | Out-File -FilePath docker-compose.yml -Encoding UTF8

# Apply fixes to sip-config.yaml
Write-Host "📞 Fixing SIP configuration..." -ForegroundColor Cyan
@'
# LiveKit SIP Service Configuration

# Required: LiveKit server connection
api_key: "108378f337bbab3ce4e944554bed555a"
api_secret: "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
ws_url: "wss://livekit-socket.immodesta.com"

# Required: Redis configuration
redis:
  address: "redis:6379"

# Logging
log_level: debug

# Health check endpoint
health_port: 8080

# SIP configuration
sip_port: 5060
rtp_port: 50000-60000

# Network settings
use_external_ip: true

# Media configuration
media_timeout: "30s"
media_timeout_initial: "10s"
enable_jitter_buffer: true

# Audio codecs
codecs:
  PCMU: true
  PCMA: true
  opus: true
  G722: true

# DTMF configuration
audio_dtmf: true

# Security and SIP behavior
hide_inbound_port: false
add_record_route: true

# SIP timing
sip_ringing_interval: "1s"
'@ | Out-File -FilePath sip-config.yaml -Encoding UTF8

Write-Host "✅ Configuration fixes applied!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Key fixes made:" -ForegroundColor Cyan
Write-Host "1. ✅ Fixed SIP config file path alignment" -ForegroundColor Green
Write-Host "2. ✅ Corrected SIP config format to match LiveKit SIP service expectations" -ForegroundColor Green
Write-Host "3. ✅ Added proper Redis configuration to SIP config" -ForegroundColor Green
Write-Host "4. ✅ Fixed port conflicts (Ingress now uses 8081)" -ForegroundColor Green
Write-Host "5. ✅ Enabled SIP health checks" -ForegroundColor Green
Write-Host "6. ✅ Removed sip-init dependency issues" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Now you can run:" -ForegroundColor Yellow
Write-Host "   docker-compose down" -ForegroundColor White
Write-Host "   docker-compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "📋 Backups saved as:" -ForegroundColor Cyan
Write-Host "   - docker-compose.yml.backup" -ForegroundColor White
Write-Host "   - sip-config.yaml.backup" -ForegroundColor White