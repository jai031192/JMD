# 🔧 SIP Configuration Fixes - November 2025

This document details the critical fixes applied to resolve SIP service startup issues.

## 🐛 Issues Found & Fixed

### 1. **Config Path Mismatch** ✅ FIXED
- **Problem**: Docker Compose mounted config to `/sip/config.yaml` but environment variable pointed to `/etc/sip/config.yaml`
- **Solution**: Updated environment variable to match mount path: `SIP_CONFIG_FILE=/sip/config.yaml`

### 2. **Incorrect SIP Config Format** ✅ FIXED
- **Problem**: `sip-config.yaml` used nested structure incompatible with LiveKit SIP service
- **Solution**: Restructured config with required root-level fields:
  - `api_key`, `api_secret`, `ws_url` at root level
  - Added proper `redis` configuration section
  - Used flat structure instead of nested

### 3. **Port Conflicts** ✅ FIXED
- **Problem**: Both SIP and Ingress services trying to use port 8080
- **Solution**: Changed Ingress port mapping to `8081:8080`

### 4. **Missing Redis Config** ✅ FIXED
- **Problem**: SIP service couldn't connect to Redis (missing config)
- **Solution**: Added Redis configuration to SIP config file

### 5. **RTP Port Range Updated** ✅ FIXED
- **Problem**: Port range mismatch between config and Docker Compose
- **Solution**: Standardized on `50000-60000` range for better compatibility

## 📂 Files Modified

### `docker-compose.yml`
```yaml
# Before
- SIP_CONFIG_FILE=/etc/sip/config.yaml
- "10000-10100:10000-10100/udp"
- "8080:8080"  # Ingress - CONFLICT!

# After  
- SIP_CONFIG_FILE=/sip/config.yaml
- "50000-60000:50000-60000/udp"
- "8081:8080"  # Ingress - No conflict
```

### `sip-config.yaml`
```yaml
# Before (BROKEN)
log_level: info
redis:
  address: livekit-redis:6379
sip:
  port: 5060
livekit:
  url: wss://livekit-socket.immodesta.com
  api_key: xxx
  api_secret: xxx

# After (WORKING)
api_key: "108378f337bbab3ce4e944554bed555a"
api_secret: "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
ws_url: "wss://livekit-socket.immodesta.com"
redis:
  address: "redis:6379"
log_level: debug
health_port: 8080
sip_port: 5060
rtp_port: 50000-60000
```

## 🚀 How to Deploy

### Option 1: Automated Deployment
```bash
# Linux/Mac/WSL
./deploy.sh

# Windows PowerShell  
.\deploy.ps1
```

### Option 2: Manual Deployment
```bash
# Start core services
docker-compose up -d redis sip

# Check logs
docker-compose logs -f sip

# Optional: Create trunk/dispatch (if Twilio configured)
docker-compose --profile init up sip-init
```

## 🔍 Verification

After deployment, verify services are working:

```bash
# Check service status
docker-compose ps

# Check SIP health
curl http://localhost:8080/health

# View SIP logs
docker-compose logs sip

# Test Redis connection
docker exec livekit-redis redis-cli ping
```

## 📞 Twilio Configuration

The auto-initialization service (`sip-init`) will only run if Twilio credentials are configured in `.env`:

```bash
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
```

If not configured, you can manually create trunks and dispatch rules:
```bash
./create-trunk-api.sh
./create-dispatch-api.sh
```

## 🎯 Expected Results

After applying fixes:
- ✅ SIP service starts successfully
- ✅ Health check responds on port 8080
- ✅ No port conflicts
- ✅ Proper Redis connectivity
- ✅ Ready for Twilio integration

## 📋 Troubleshooting

If issues persist:

1. **Check Docker logs**: `docker-compose logs sip`
2. **Verify config syntax**: `docker exec livekit-sip cat /sip/config.yaml`
3. **Test Redis**: `docker exec livekit-redis redis-cli ping`
4. **Check ports**: `netstat -tulpn | grep :5060`

---
*Applied: November 6, 2025*
*Status: ✅ Ready for production*