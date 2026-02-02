# RESILIENCE 系統韌性與自我恢復

## Self-Healing Configuration (自我恢復配置)

### ⚠️ MANDATORY REQUIREMENTS (強制要求)

**All production deployments MUST meet these requirements:**

1. **Docker must be enabled to auto-start on OS boot**
2. **All services must have `restart: always` policy**
3. **Health checks must be configured for all critical services**
4. **Hard reboot test must be performed before production acceptance**

**Failure to comply with these requirements will result in deployment rejection.**

---

## Docker Service Auto-Start Configuration (Docker 服務自動啟動配置)

### Enable Docker on System Boot (啟用 Docker 開機自動啟動)

**⚠️ CRITICAL**: This prevents the incident where Docker fails to start after server reboot.

```bash
# Enable Docker service
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Verify Docker is enabled (MUST show "enabled")
sudo systemctl is-enabled docker.service
# Expected output: enabled

sudo systemctl is-enabled containerd.service
# Expected output: enabled

# Check Docker service status
sudo systemctl status docker.service
# Expected output: Active: active (running)

# If Docker is not enabled, the output will show "disabled"
```

### Verification Commands (驗證命令)

Run these commands on every new server setup:

```bash
# Check if Docker daemon will start on boot
systemctl is-enabled docker.service

# Expected output: "enabled"
# If output is "disabled", Docker will NOT start on reboot ❌

# Check containerd (required by Docker)
systemctl is-enabled containerd.service

# View current systemd configuration
systemctl show docker.service | grep -i "enabled\|wantedby"

# Verify Docker starts automatically after reboot
sudo systemctl get-default
# Expected: multi-user.target or graphical.target
```

### Manual Verification After System Reboot (重啟後人工驗證)

```bash
# After a server reboot, verify:

# 1. Docker service is running
sudo systemctl status docker.service | grep "Active:"
# Must show: Active: active (running)

# 2. All containers restarted automatically
docker ps -a
# All containers should show status "Up X minutes" not "Exited"

# 3. Check container restart count
docker inspect <container_name> | grep -i "restartcount"
# Should be > 0 if container restarted after reboot
```

---

## Standard docker-compose.yml with Restart Policy (標準 docker-compose.yml 重啟策略)

### Complete Example (完整範例)

```yaml
version: '3.9'

services:
  # Nginx Reverse Proxy
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx
    restart: always  # ⚠️ MANDATORY: Auto-restart on failure or reboot
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      api-service:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # API Service
  api-service:
    image: your-org/api-service:latest
    container_name: api-service
    restart: always  # ⚠️ MANDATORY
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=${NODE_ENV}
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - REDIS_HOST=redis
    env_file:
      - .env
    volumes:
      - ./logs/api:/app/logs
      - ./uploads:/app/uploads
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: always  # ⚠️ MANDATORY
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${DATABASE_NAME}
      - POSTGRES_USER=${DATABASE_USER}
      - POSTGRES_PASSWORD=${DATABASE_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DATABASE_USER} -d ${DATABASE_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    shm_size: 256mb  # Increase shared memory for better performance

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: always  # ⚠️ MANDATORY
    ports:
      - "6379:6379"
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  # Background Worker
  worker-service:
    image: your-org/worker-service:latest
    container_name: worker-service
    restart: always  # ⚠️ MANDATORY
    environment:
      - NODE_ENV=${NODE_ENV}
      - DATABASE_HOST=postgres
      - REDIS_HOST=redis
    env_file:
      - .env
    volumes:
      - ./logs/worker:/app/logs
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    # Note: Worker services may not have HTTP health checks
    # Monitor via logs and process status

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  app-network:
    driver: bridge
```

### Restart Policy Options (重啟策略選項)

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `restart: always` | **Always restart**, even after manual stop | **Production services** (databases, APIs) |
| `restart: unless-stopped` | Restart unless manually stopped | Services that need manual control |
| `restart: on-failure` | Only restart if exit code is non-zero | Dev/test environments |
| `restart: "no"` | Never restart automatically | One-time migration scripts |

**⚠️ For production, ALWAYS use `restart: always`**

---

## Health Check Configuration (健康檢查配置)

### Best Practices (最佳實踐)

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s        # Check every 30 seconds
  timeout: 10s         # Fail if no response within 10 seconds
  retries: 3           # Retry 3 times before marking unhealthy
  start_period: 60s    # Grace period during container startup
```

### Health Check Endpoints (健康檢查端點)

All services must expose a health check endpoint that returns:
- **200 OK**: Service is healthy
- **503 Service Unavailable**: Service is unhealthy

Example response:

```json
{
  "status": "healthy",
  "timestamp": "2026-02-02T10:30:00Z",
  "uptime": 3600,
  "dependencies": {
    "database": "connected",
    "cache": "connected"
  }
}
```

---

## Recovery SOP (Standard Operating Procedures) (故障恢復標準作業程序)

| Failure Scenario | Symptoms | Detection Method | Recovery Steps | Prevention |
|------------------|----------|------------------|----------------|------------|
| **Docker not running after reboot** | All containers down, `docker ps` fails | `systemctl status docker.service` shows inactive | `sudo systemctl start docker.service` | **Enable Docker**: `sudo systemctl enable docker.service` |
| **Container exited and not restarting** | Service unavailable, container status: Exited | `docker ps -a` shows `Exited (1)` | 1. Check logs: `docker logs <container>`<br>2. Fix issue<br>3. `docker-compose up -d` | **Ensure `restart: always` in compose file** |
| **Database connection pool exhausted** | API returns 500, logs show "connection timeout" | Monitor connection count | 1. Restart API service<br>2. Increase `DATABASE_POOL_MAX` | Implement connection pooling with proper limits |
| **Disk full (logs/data)** | Services crash, "no space left on device" | `df -h` shows 100% usage | 1. Clean old logs: `docker-compose logs --tail=0`<br>2. Prune unused images: `docker system prune -a` | Implement log rotation, monitor disk usage |
| **Memory leak causing OOM** | Container randomly killed, `docker inspect` shows OOMKilled | `docker inspect <container> \| grep OOMKilled` | 1. Restart container<br>2. Increase memory limit<br>3. Investigate leak | Set memory limits, use health checks with restart |
| **Port conflict after reboot** | Container fails to start, "bind: address already in use" | `docker logs <container>` | 1. Find process: `sudo lsof -i :PORT`<br>2. Kill process or change port | Reserve ports, document port usage |
| **SSL certificate expired** | HTTPS fails with certificate error | Browser warning, `curl` shows cert error | 1. Renew cert: `sudo certbot renew`<br>2. Reload Nginx: `docker-compose restart nginx` | Automate renewal with certbot timer |
| **Database corruption** | Queries fail, integrity errors in logs | PostgreSQL logs show corruption | 1. Stop services<br>2. Restore from last backup<br>3. Replay WAL logs | Regular backups, enable WAL archiving |
| **Redis data loss** | Session/cache miss, users logged out | All cache keys empty, Redis restarted | 1. Restart API (will repopulate cache)<br>2. Users re-login | Enable Redis persistence (AOF), regular backups |

### Emergency Contact Escalation (緊急聯繫升級)

| Severity | Response Time | Contact | Escalation Path |
|----------|---------------|---------|-----------------|
| **Critical** (All services down) | 15 minutes | On-call engineer (phone) | → DevOps Lead → CTO |
| **High** (Partial outage) | 30 minutes | On-call engineer (Slack) | → DevOps Lead |
| **Medium** (Degraded performance) | 2 hours | Team Slack channel | → Team Lead |
| **Low** (Non-critical issue) | Next business day | Ticket system | → Team backlog |

---

## Automated Recovery Scripts (自動恢復腳本)

### 1. Service Health Monitor & Auto-Restart (服務健康監控與自動重啟)

```bash
#!/bin/bash
# File: /opt/scripts/health-monitor.sh
# Schedule with cron: */5 * * * * /opt/scripts/health-monitor.sh

SERVICES=("api-service" "postgres" "redis" "nginx")
LOG_FILE="/var/log/health-monitor.log"

for SERVICE in "${SERVICES[@]}"; do
  if ! docker ps | grep -q "$SERVICE"; then
    echo "$(date): $SERVICE is down, attempting restart..." >> "$LOG_FILE"
    docker-compose -f /opt/app/docker-compose.yml up -d "$SERVICE"
    
    # Send alert (replace with your alerting system)
    curl -X POST "https://your-alerting-service.com/alert" \
      -H "Content-Type: application/json" \
      -d "{\"service\": \"$SERVICE\", \"status\": \"restarted\", \"timestamp\": \"$(date -Iseconds)\"}"
  fi
done
```

### 2. Post-Reboot Verification (重啟後驗證)

```bash
#!/bin/bash
# File: /opt/scripts/post-reboot-check.sh
# Run via systemd service after boot

COMPOSE_FILE="/opt/app/docker-compose.yml"
EXPECTED_CONTAINERS=5  # Adjust based on your services
WAIT_TIME=120  # Wait 2 minutes for services to start

echo "Waiting $WAIT_TIME seconds for services to start..."
sleep "$WAIT_TIME"

# Check Docker is running
if ! systemctl is-active --quiet docker.service; then
  echo "ERROR: Docker service is not running!"
  systemctl start docker.service
  exit 1
fi

# Check all containers are up
RUNNING_CONTAINERS=$(docker ps --filter "status=running" --format "{{.Names}}" | wc -l)

if [ "$RUNNING_CONTAINERS" -lt "$EXPECTED_CONTAINERS" ]; then
  echo "ERROR: Only $RUNNING_CONTAINERS/$EXPECTED_CONTAINERS containers running"
  docker-compose -f "$COMPOSE_FILE" up -d
  exit 1
fi

echo "SUCCESS: All $RUNNING_CONTAINERS containers are running"
```

### 3. Systemd Service for Post-Reboot Check (Systemd 服務)

```ini
# File: /etc/systemd/system/app-post-reboot.service

[Unit]
Description=Application Post-Reboot Health Check
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/opt/scripts/post-reboot-check.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable the service:**

```bash
sudo systemctl enable app-post-reboot.service
```

---

## Monitoring & Alerting Integration (監控與告警整合)

### Prometheus Alerting Rules (Prometheus 告警規則)

```yaml
# File: prometheus/alerts.yml

groups:
  - name: container_health
    interval: 30s
    rules:
      - alert: ContainerDown
        expr: up{job="docker"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"
      
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.name }} high memory usage"
          description: "Memory usage is above 90% for 5 minutes"
      
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.name }} high CPU usage"
          description: "CPU usage is above 80% for 10 minutes"
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-02  
**Maintained By**: DevOps & Infrastructure Team  
**Review Cycle**: After every incident or quarterly  
**Next Review**: 2026-05-02
