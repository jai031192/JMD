# LiveKit Self-Hosted Complete Setup

Complete production-ready LiveKit deployment on Azure with full feature parity to LiveKit Cloud.

## 🎯 Features

- ✅ **LiveKit Server** with full configuration
- ✅ **Redis** for state management & pub/sub
- ✅ **SIP Gateway** for telephony integration
- ✅ **Egress** for recording & streaming
- ✅ **Ingress** for RTMP/WHIP input
- ✅ **LiveKit CLI** for management
- ✅ **Embedded TURN Server** for NAT traversal
- ✅ All codecs enabled (Opus, RED, VP8, H.264, VP9, AV1, H.265)
- ✅ Prometheus metrics
- ✅ WebHook support
- ✅ Agents framework

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Azure VM / Cloud                     │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │   LiveKit    │  │    Redis     │  │   SIP    │ │
│  │    Server    │──│  (State)     │──│ Gateway  │ │
│  └──────────────┘  └──────────────┘  └──────────┘ │
│         │                │                  │       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │   Egress     │  │   Ingress    │  │ LK CLI   │ │
│  │ (Recording)  │  │ (RTMP/WHIP)  │  │  Tools   │ │
│  └──────────────┘  └──────────────┘  └──────────┘ │
└─────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/jai031192/JMD.git
cd JMD
```

### 2. Configure Environment
```bash
# Copy templates
cp .env.template .env
cp livekit.yaml.template livekit.yaml
cp sip-config.yaml.template sip-config.yaml
cp egress-config.yaml.template egress-config.yaml
cp ingress-config.yaml.template ingress-config.yaml

# Edit .env with your values
nano .env
```

### 3. Update Configuration
Edit `livekit.yaml` and set:
- Your API keys
- Your Azure public IP in `rtc.node_ip`
- Your domain name

### 4. Start Services
```bash
# Start Redis + SIP only
docker-compose up -d

# Or start everything (Redis + SIP + Egress + Ingress + CLI)
docker-compose --profile full --profile tools up -d
```

### 5. Verify
```bash
docker-compose ps
docker-compose logs -f
```

## 📋 Azure Network Security Group Rules

| Port Range | Protocol | Purpose |
|------------|----------|---------|
| 7880 | TCP | LiveKit HTTP/WebSocket |
| 7881 | TCP | LiveKit ICE/TCP |
| 50000-60000 | UDP | LiveKit RTP/RTCP media |
| 3478 | UDP | TURN server |
| 5349 | TCP | TURNS server (TLS) |
| 30000-40000 | UDP | TURN relay ports |
| 5060 | UDP/TCP | SIP signaling |
| 10000-10100 | UDP | SIP RTP media |
| 1935 | TCP | RTMP ingress |
| 8080 | TCP | WHIP ingress |
| 6789 | TCP | Prometheus metrics |

## 🔧 LiveKit CLI Usage

### Start CLI Container
```bash
docker-compose --profile tools up -d livekit-cli
```

### Use CLI
```bash
# Windows
.\lk.ps1 sip trunk list
.\lk.ps1 room list

# Linux
./lk.sh sip trunk list
./lk.sh room list
```

### Create SIP Trunk
```bash
.\lk.ps1 sip trunk create \
  --name MyTrunk \
  --address sip:provider.com:5060 \
  --username your-username \
  --password your-password \
  --outbound-number +1234567890
```

### Create Dispatch Rule
```bash
# Get trunk ID first
.\lk.ps1 sip trunk list

# Create dispatch
.\lk.ps1 sip dispatch create \
  --trunk-id TRUNK_ID \
  --name my-dispatch \
  --rule-type individual \
  --room-prefix call-
```

## 📚 Documentation

- **[SETUP.txt](SETUP.txt)** - Complete setup guide
- **[CLI-USAGE.md](CLI-USAGE.md)** - CLI command reference
- **[CONFIG-MERGE-GUIDE.md](CONFIG-MERGE-GUIDE.md)** - Configuration merge guide
- **[GITHUB-SETUP.md](GITHUB-SETUP.md)** - GitHub deployment guide

## 🎛️ Services

### Redis
State management and pub/sub for distributed LiveKit deployment.
- **Port:** 6379
- **Data:** Persistent with AOF

### SIP Gateway
Connect phone calls to LiveKit rooms.
- **Ports:** 5060 (TCP/UDP), 10000-10100 (UDP)
- **Features:** Inbound/outbound trunks, dispatch rules

### Egress
Record rooms and export to files or streams.
- **Outputs:** MP4, WebM, HLS, RTMP
- **Storage:** Local, S3, Azure Blob, GCP

### Ingress
Stream from OBS, FFmpeg, or WHIP clients.
- **Ports:** 1935 (RTMP), 8080 (WHIP)
- **Features:** Transcoding, multi-track

### LiveKit CLI
Manage trunks, dispatch rules, rooms, and tokens.
- **Helper Scripts:** `lk.ps1` (Windows), `lk.sh` (Linux)
- **Pre-made Scripts:** In `cli-scripts/` directory

## 🔐 Security Notes

- ⚠️ **Never commit** `.env` or `livekit.yaml` with real credentials
- ✅ Use `.template` files in the repository
- ✅ Set strong Redis passwords
- ✅ Use 32+ character API secrets
- ✅ Enable TLS for TURN server in production
- ✅ Restrict Redis access to localhost or use authentication

## 📊 Monitoring

Access Prometheus metrics:
```
http://your-server:6789/metrics
```

## 🛠️ Management

```bash
# View logs
docker-compose logs -f

# Restart service
docker-compose restart sip

# Stop all
docker-compose down

# Update images
docker-compose pull
docker-compose up -d
```

## 🤝 Contributing

This is a personal deployment setup. Feel free to fork and customize for your needs.

## 📄 License

This configuration is provided as-is for self-hosted LiveKit deployments.

## 🔗 Resources

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit Self-Hosting Guide](https://docs.livekit.io/home/self-hosting/deployment/)
- [SIP Documentation](https://docs.livekit.io/sip/)
- [Egress Documentation](https://docs.livekit.io/egress/)
- [Ingress Documentation](https://docs.livekit.io/ingress/)

## 🆘 Support

- LiveKit Slack: https://livekit.io/join-slack
- LiveKit GitHub: https://github.com/livekit/livekit
- LiveKit Forum: https://github.com/livekit/livekit/discussions

---

**Deployed on Azure** | **Self-Hosted** | **Production Ready**
