# DEPLOY 部署指南

## Prerequisites (前置需求)

### System Requirements
- **OS**: Ubuntu 22.04 LTS / Debian 11+ / RHEL 8+
- **Docker**: 24.0+ 
- **Docker Compose**: v2.20+
- **Git**: 2.30+
- **Network**: Internet access for initial setup, closed network for production

### Required Access
- [ ] SSH access with sudo privileges
- [ ] Git repository access (SSH key or access token)
- [ ] Production `.env` file from secrets manager
- [ ] SSL certificates (if applicable)

---

## Environment Variables (環境變數配置)

### `.env` Configuration Table

| Key | Description | Example | Required | Default |
|-----|-------------|---------|----------|---------|
| `NODE_ENV` | Application environment | `production` / `staging` / `development` | **Yes** | - |
| `APP_PORT` | Main application port | `8080` | **Yes** | - |
| `DATABASE_HOST` | PostgreSQL hostname | `postgres` (Docker) / `db.example.com` (external) | **Yes** | - |
| `DATABASE_PORT` | PostgreSQL port | `5432` | **Yes** | `5432` |
| `DATABASE_NAME` | Database name | `app_production` | **Yes** | - |
| `DATABASE_USER` | Database username | `app_user` | **Yes** | - |
| `DATABASE_PASSWORD` | Database password | `SecureP@ssw0rd!` | **Yes** | - |
| `DATABASE_SSL` | Enable SSL connection | `true` / `false` | No | `false` |
| `REDIS_HOST` | Redis hostname | `redis` (Docker) / `cache.example.com` (external) | **Yes** | - |
| `REDIS_PORT` | Redis port | `6379` | **Yes** | `6379` |
| `REDIS_PASSWORD` | Redis password | `RedisSecure123` | No | - |
| `JWT_SECRET` | JWT signing key | `your-256-bit-secret-key-here` | **Yes** | - |
| `JWT_EXPIRES_IN` | Token expiration time | `15m` / `1h` / `7d` | No | `15m` |
| `SMTP_HOST` | Email server hostname | `smtp.sendgrid.net` | No | - |
| `SMTP_PORT` | Email server port | `587` | No | `587` |
| `SMTP_USER` | SMTP username | `apikey` | No | - |
| `SMTP_PASSWORD` | SMTP password | `SG.xxxxxxxxxxxxx` | No | - |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAIOSFODNN7EXAMPLE` | No | - |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` | No | - |
| `AWS_S3_BUCKET` | S3 bucket name | `my-app-uploads` | No | - |
| `LOG_LEVEL` | Logging verbosity | `error` / `warn` / `info` / `debug` | No | `info` |
| `CORS_ORIGIN` | Allowed CORS origins | `https://example.com,https://www.example.com` | No | `*` |
| `RATE_LIMIT_REQUESTS` | Max requests per window | `100` | No | `100` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window (ms) | `60000` (1 min) | No | `60000` |

### `.env` File Template

```bash
# Application Configuration
NODE_ENV=production
APP_PORT=8080
APP_URL=https://api.example.com

# Database Configuration
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=app_production
DATABASE_USER=app_user
DATABASE_PASSWORD=CHANGE_ME_STRONG_PASSWORD
DATABASE_SSL=false
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD
REDIS_DB=0

# Security
JWT_SECRET=CHANGE_ME_256_BIT_SECRET_KEY
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
SESSION_SECRET=CHANGE_ME_SESSION_SECRET

# External Services
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=CHANGE_ME_SENDGRID_API_KEY

# AWS S3
AWS_ACCESS_KEY_ID=CHANGE_ME_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=CHANGE_ME_AWS_SECRET_KEY
AWS_S3_BUCKET=my-app-uploads
AWS_REGION=us-east-1

# Monitoring & Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW_MS=60000
```

---

## Step-by-Step Deployment (部署步驟)

### 1. Initial Server Setup (初始伺服器設置)

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl git ufw fail2ban

# Configure firewall
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw --force enable
```

### 2. Install Docker & Docker Compose (安裝 Docker)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose (if not included)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 3. Configure Docker Auto-Start (配置 Docker 自動啟動)

**⚠️ CRITICAL**: This step prevents the reboot failure incident.

```bash
# Enable Docker service to start on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Verify Docker is enabled
sudo systemctl is-enabled docker.service    # Should output: enabled
sudo systemctl is-enabled containerd.service # Should output: enabled

# Check current status
sudo systemctl status docker.service
```

### 4. Clone Repository (克隆代碼庫)

```bash
# Navigate to deployment directory
cd /opt

# Clone the repository (via SSH)
sudo git clone git@github.com:your-org/your-project.git app
sudo chown -R $USER:$USER /opt/app

# Or clone via HTTPS with token
sudo git clone https://YOUR_TOKEN@github.com/your-org/your-project.git app

cd /opt/app
```

### 5. Configure Environment (配置環境)

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables (use your preferred editor)
nano .env

# Validate .env file (check for syntax errors)
docker-compose config --quiet
```

### 6. Set Up Volumes & Permissions (設置卷和權限)

```bash
# Create necessary directories for persistent data
sudo mkdir -p /opt/app/data/postgres
sudo mkdir -p /opt/app/data/redis
sudo mkdir -p /opt/app/logs
sudo mkdir -p /opt/app/backups

# Set proper permissions
sudo chown -R 1000:1000 /opt/app/data
sudo chown -R 1000:1000 /opt/app/logs
sudo chmod -R 755 /opt/app/data
```

### 7. Pull Docker Images (拉取 Docker 鏡像)

```bash
# Pull all images defined in docker-compose.yml
docker-compose pull

# Verify images
docker images
```

### 8. Start Services (啟動服務)

```bash
# Start all services in detached mode
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 9. Database Migration (資料庫遷移)

```bash
# Run database migrations
docker-compose exec api-service npm run migrate

# Or using a separate migration container
docker-compose run --rm migration-service

# Verify migration status
docker-compose exec api-service npm run migrate:status
```

### 10. Health Check Verification (健康檢查驗證)

```bash
# Wait for services to be ready (30 seconds)
sleep 30

# Check API health endpoint
curl -f http://localhost:8080/health || echo "API health check failed"

# Check Auth service
curl -f http://localhost:8081/auth/health || echo "Auth health check failed"

# Check PostgreSQL
docker-compose exec postgres pg_isready -U app_user || echo "PostgreSQL not ready"

# Check Redis
docker-compose exec redis redis-cli ping || echo "Redis not responding"

# Check all containers are running
docker-compose ps | grep -v "Up" && echo "Some containers are not running!"
```

### 11. Configure SSL/TLS (Optional) (配置 SSL/TLS)

```bash
# Install certbot (for Let's Encrypt)
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d api.example.com -d www.example.com

# Verify auto-renewal
sudo certbot renew --dry-run

# Configure auto-renewal cron job
sudo systemctl enable certbot.timer
```

### 12. Set Up Monitoring (Optional) (設置監控)

```bash
# Start monitoring stack (if included)
docker-compose -f docker-compose.monitoring.yml up -d

# Access Grafana at http://YOUR_SERVER_IP:3000
# Default credentials: admin / admin (change immediately)
```

---

## Volume Mounting Rules (卷掛載規則)

### Standard Volume Mappings

| Host Path | Container Path | Purpose | Backup Required | Notes |
|-----------|----------------|---------|-----------------|-------|
| `/opt/app/data/postgres` | `/var/lib/postgresql/data` | PostgreSQL data files | **Yes** (Critical) | Must survive container restarts |
| `/opt/app/data/redis` | `/data` | Redis persistence (RDB/AOF) | **Yes** | Enable RDB snapshots in config |
| `/opt/app/logs` | `/app/logs` | Application logs | No | Rotate with logrotate |
| `/opt/app/uploads` | `/app/uploads` | User uploaded files | **Yes** (Critical) | Consider S3 instead for scale |
| `/opt/app/backups` | `/backups` | Database backup files | **Yes** | Offsite backup recommended |
| `/opt/app/config` | `/app/config` | Configuration files | **Yes** | Version-controlled configs only |
| `/etc/letsencrypt` | `/etc/letsencrypt` | SSL certificates | **Yes** | Required for HTTPS |

### Volume Permission Best Practices

```bash
# PostgreSQL requires specific UID/GID
sudo chown -R 999:999 /opt/app/data/postgres

# Redis default user
sudo chown -R 999:999 /opt/app/data/redis

# Application files (usually UID 1000)
sudo chown -R 1000:1000 /opt/app/logs
sudo chown -R 1000:1000 /opt/app/uploads

# Prevent permission-related issues
sudo chmod -R 755 /opt/app/data
```

---

## Deployment Verification Checklist (部署驗證清單)

- [ ] All containers are running (`docker-compose ps`)
- [ ] All health checks return 200 OK
- [ ] Database migrations applied successfully
- [ ] Environment variables loaded correctly (no hardcoded secrets)
- [ ] Logs are being written to `/opt/app/logs`
- [ ] Docker service is enabled (`systemctl is-enabled docker`)
- [ ] All services have `restart: always` in `docker-compose.yml`
- [ ] Firewall rules configured correctly
- [ ] SSL certificates installed (production only)
- [ ] Backups scheduled and tested
- [ ] Monitoring dashboards accessible
- [ ] DNS records pointing to server IP

---

## Common Deployment Issues (常見部署問題)

| Issue | Symptom | Solution |
|-------|---------|----------|
| Port already in use | `Error starting userland proxy: listen tcp 0.0.0.0:8080: bind: address already in use` | `sudo lsof -i :8080` then `kill <PID>` or change port in `.env` |
| Permission denied on volume | `mkdir: cannot create directory '/var/lib/postgresql/data': Permission denied` | Check volume permissions: `sudo chown -R 999:999 /opt/app/data/postgres` |
| Database connection refused | `Error: connect ECONNREFUSED 127.0.0.1:5432` | Use Docker service name (`DATABASE_HOST=postgres`) not `localhost` |
| Out of disk space | `no space left on device` | Clean up: `docker system prune -a --volumes` (⚠️ removes unused data) |
| Network not found | `network not found` | `docker network create app-network` or remove `external: true` from compose file |

---

## Rollback Procedure (回滾程序)

See [TEST_REPORT.md](./TEST_REPORT.md) for detailed rollback steps.

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-02  
**Maintained By**: DevOps Team  
**Review Cycle**: After every major deployment
