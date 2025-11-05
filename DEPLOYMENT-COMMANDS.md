# Quick Start Commands After Clone

## 🚀 Step-by-Step Deployment

### 1. Navigate to Directory
```powershell
cd JMD
```

### 2. Create Configuration Files from Templates
```powershell
# Copy .env file and edit it with your credentials
Copy-Item .env.template .env
notepad .env

# Copy LiveKit config and edit with your settings
Copy-Item livekit.yaml.template livekit.yaml
notepad livekit.yaml

# Copy SIP config
Copy-Item sip-config.yaml.template sip-config.yaml
notepad sip-config.yaml

# Copy Egress config (optional)
Copy-Item egress-config.yaml.template egress-config.yaml
notepad egress-config.yaml

# Copy Ingress config (optional)
Copy-Item ingress-config.yaml.template ingress-config.yaml
notepad ingress-config.yaml
```

### 3. Build and Start Services

#### Option A: Minimal Setup (Redis + SIP only)
```powershell
docker-compose up -d
```

#### Option B: Full Setup (Redis + SIP + Egress + Ingress)
```powershell
docker-compose --profile full up -d
```

#### Option C: Everything Including CLI Tools
```powershell
docker-compose --profile full --profile tools up -d
```

### 4. Verify Services are Running
```powershell
# Check all containers
docker-compose ps

# View logs
docker-compose logs -f

# Check specific service
docker-compose logs -f sip
docker-compose logs -f redis
```

### 5. Test Redis Connection
```powershell
docker exec livekit-redis redis-cli ping
# Should return: PONG
```

### 6. Use LiveKit CLI (if you started with --profile tools)
```powershell
# List SIP trunks
.\lk.ps1 sip trunk list

# List rooms
.\lk.ps1 room list

# Create a test token
.\lk.ps1 token create --join --room test-room --identity test-user
```

## 🛠️ Common Docker Compose Commands

### Start Services
```powershell
# Start in background
docker-compose up -d

# Start with logs visible
docker-compose up

# Start specific services
docker-compose up -d redis sip
```

### Stop Services
```powershell
# Stop all services
docker-compose down

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v

# Stop specific service
docker-compose stop sip
```

### View Status & Logs
```powershell
# List running containers
docker-compose ps

# View logs (all services)
docker-compose logs -f

# View logs (specific service)
docker-compose logs -f sip

# View last 100 lines
docker-compose logs --tail=100 redis
```

### Restart Services
```powershell
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart sip
```

### Update Images
```powershell
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --force-recreate
```

### Scale Services
```powershell
# Run multiple SIP gateways
docker-compose up -d --scale sip=3
```

## 🔧 Troubleshooting Commands

### Check Container Health
```powershell
docker-compose ps
docker inspect livekit-redis
docker inspect livekit-sip
```

### Enter Container Shell
```powershell
# Enter Redis container
docker exec -it livekit-redis sh

# Enter SIP container
docker exec -it livekit-sip sh

# Enter CLI container
docker exec -it livekit-cli sh
```

### View Container Resources
```powershell
# Check CPU/Memory usage
docker stats

# Check specific container
docker stats livekit-redis livekit-sip
```

### Clean Up
```powershell
# Remove stopped containers
docker-compose rm

# Remove all (containers, networks, volumes)
docker-compose down -v

# Prune unused Docker resources
docker system prune -a
```

## 📋 Service Profiles Explained

### Default (no profile)
Starts: **Redis + SIP**
```powershell
docker-compose up -d
```

### Profile: `full`
Starts: **Redis + SIP + Egress + Ingress**
```powershell
docker-compose --profile full up -d
```

### Profile: `tools`
Starts: **LiveKit CLI container**
```powershell
docker-compose --profile tools up -d
```

### Combined Profiles
Starts: **Everything**
```powershell
docker-compose --profile full --profile tools up -d
```

## ⚡ Quick Reference

| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start minimal setup (Redis + SIP) |
| `docker-compose --profile full up -d` | Start all services |
| `docker-compose down` | Stop all services |
| `docker-compose ps` | List running containers |
| `docker-compose logs -f` | Follow logs |
| `docker-compose restart sip` | Restart SIP service |
| `docker-compose pull` | Update images |
| `docker exec -it livekit-cli sh` | Enter CLI container |

## 🎯 Recommended First Run

```powershell
# 1. Configure your files
Copy-Item .env.template .env
notepad .env

# 2. Start minimal services
docker-compose up -d

# 3. Check status
docker-compose ps

# 4. View logs
docker-compose logs -f

# 5. Test Redis
docker exec livekit-redis redis-cli ping
```

## 🔍 Verify Deployment

After starting, verify each service:

```powershell
# Check Redis
docker exec livekit-redis redis-cli ping

# Check SIP health (if configured)
curl http://localhost:8080/health

# Check all containers
docker-compose ps

# Check logs for errors
docker-compose logs --tail=50
```

## 🆘 If Something Goes Wrong

```powershell
# Check what's wrong
docker-compose ps
docker-compose logs

# Restart everything
docker-compose restart

# Complete reset
docker-compose down
docker-compose up -d

# Nuclear option (removes all data)
docker-compose down -v
docker-compose up -d
```
