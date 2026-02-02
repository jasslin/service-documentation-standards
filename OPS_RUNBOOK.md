# Operations Runbook Index
# 運維手冊索引

**Purpose**: Quick navigation to all service documentation  
**目的**：快速導航到所有服務文檔

**Last Updated**: 2026-02-02

---

## How to Use This Index (如何使用本索引)

Each production service maintains its own documentation in its repository:
- `docs/ARCHITECTURE.md` — System design and dependencies
- `docs/DEPLOY.md` — Deployment procedures
- `docs/RESILIENCE.md` — Self-healing configuration
- `docs/TEST_REPORT.md` — Verification results

**This index provides direct links to those locations.**  
**本索引提供直接連結到這些位置。**

---

## Production Services (生產服務)

### Flemabus (Vehicle Detection & Recognition)

**Repository**: `git@github.com:jasslin/flemabus.git`  
**Production Server**: `production-server-01:/opt/flemabus/`

| Document | Location | Purpose |
|----------|----------|---------|
| **ARCHITECTURE** | `/opt/flemabus/docs/ARCHITECTURE.md` | System design, API dependencies, network topology |
| **DEPLOY** | `/opt/flemabus/docs/DEPLOY.md` | Deployment steps, environment variables, volume configuration |
| **RESILIENCE** | `/opt/flemabus/docs/RESILIENCE.md` | Docker restart policies, health checks, recovery procedures |
| **TEST_REPORT** | `/opt/flemabus/docs/TEST_REPORT.md` | Staging verification results, hard reboot test |

**Current Version**: `v2.1.0`  
**Last Deployed**: 2026-02-01  
**On-Call Engineer**: Ezra Wu (吳豐吉)

**Quick Commands**:
```bash
# Check status
cd /opt/flemabus && docker-compose ps

# View logs
docker-compose logs -f --tail=100

# Rollback
git checkout v2.0.5 && docker-compose up -d
```

---

### [Service Name 2] (Service Description)

**Repository**: `git@github.com:jasslin/[service-name].git`  
**Production Server**: `[server]:/opt/[service-name]/`

| Document | Location | Purpose |
|----------|----------|---------|
| **ARCHITECTURE** | `/opt/[service-name]/docs/ARCHITECTURE.md` | System design |
| **DEPLOY** | `/opt/[service-name]/docs/DEPLOY.md` | Deployment procedures |
| **RESILIENCE** | `/opt/[service-name]/docs/RESILIENCE.md` | Self-healing configuration |
| **TEST_REPORT** | `/opt/[service-name]/docs/TEST_REPORT.md` | Verification results |

**Current Version**: `v[x.y.z]`  
**Last Deployed**: YYYY-MM-DD  
**On-Call Engineer**: [Name]

**Quick Commands**:
```bash
# [Add service-specific commands]
```

---

### [Service Name 3] (Service Description)

**Repository**: `git@github.com:jasslin/[service-name].git`  
**Production Server**: `[server]:/opt/[service-name]/`

| Document | Location | Purpose |
|----------|----------|---------|
| **ARCHITECTURE** | `/opt/[service-name]/docs/ARCHITECTURE.md` | System design |
| **DEPLOY** | `/opt/[service-name]/docs/DEPLOY.md` | Deployment procedures |
| **RESILIENCE** | `/opt/[service-name]/docs/RESILIENCE.md` | Self-healing configuration |
| **TEST_REPORT** | `/opt/[service-name]/docs/TEST_REPORT.md` | Verification results |

**Current Version**: `v[x.y.z]`  
**Last Deployed**: YYYY-MM-DD  
**On-Call Engineer**: [Name]

---

## Documentation Standards (文檔標準)

### Each Service MUST Maintain:

1. **ARCHITECTURE.md**
   - Mermaid diagram of system components
   - Service inventory (name, port, purpose)
   - 3rd-party API dependencies
   - Security boundaries

2. **DEPLOY.md**
   - Step-by-step deployment instructions
   - Environment variables table
   - Volume mounting configuration
   - Pre-deployment checklist

3. **RESILIENCE.md**
   - Docker restart policies (`restart: always`)
   - Health check configuration
   - Recovery SOP (Standard Operating Procedure)
   - Hard reboot verification

4. **TEST_REPORT.md**
   - Staging environment test results
   - Hard reboot test confirmation
   - Performance benchmarks
   - Sign-off record

**Templates**: Available at `/templates/docs/` in this repository

---

## Adding a New Service (新增服務)

### When deploying a new service to production:

1. **Create documentation** using templates:
   ```bash
   cp -r /path/to/documentation-management/templates/docs/ ./docs/
   ```

2. **Fill in all 4 documents** (ARCHITECTURE, DEPLOY, RESILIENCE, TEST_REPORT)

3. **Validate** using Hard Gates:
   ```bash
   bash /path/to/documentation-management/scripts/validate-hardgates.sh
   ```

4. **Add entry to this index**:
   - Service name and description
   - Repository URL
   - Production server path
   - Documentation locations
   - On-call engineer

5. **Submit PR** to `documentation-management` repository to update this index

---

## Emergency Procedures (緊急程序)

### If Service is Down:

1. **Check service status**:
   ```bash
   cd /opt/[service-name]
   docker-compose ps
   docker-compose logs -f
   ```

2. **Locate documentation**:
   - Find service in this index
   - Read RESILIENCE.md for recovery steps

3. **Attempt rollback** (if recent deployment):
   ```bash
   cd /opt/[service-name]
   git tag -l  # List available versions
   git checkout v[previous-version]
   docker-compose up -d
   ```

4. **If recovery fails**:
   - Contact on-call engineer (listed above)
   - Escalate to Engineering Lead
   - Follow incident response procedures in RESILIENCE.md

---

## Common Operational Commands (常用運維指令)

### Check All Services:

```bash
# On production server
for service in /opt/*/; do
  echo "=== $(basename $service) ==="
  cd $service
  docker-compose ps
  echo ""
done
```

### Verify Docker Auto-Start:

```bash
sudo systemctl is-enabled docker.service
# Should output: enabled
```

### Check Service Health:

```bash
cd /opt/[service-name]
docker-compose ps
# All containers should show "Up" status
```

### View Recent Logs:

```bash
cd /opt/[service-name]
docker-compose logs -f --tail=100 [container-name]
```

### Restart Service (Safe):

```bash
cd /opt/[service-name]
docker-compose restart [service-name]
```

---

## Maintenance Schedule (維護時程)

### Regular Tasks:

| Task | Frequency | Responsible |
|------|-----------|-------------|
| Verify all services running | Daily | On-call engineer |
| Review service logs | Daily | On-call engineer |
| Update documentation | On each deployment | Deployment engineer |
| Test rollback capability | Monthly | Engineering team |
| Hard reboot test (staging) | Quarterly | Engineering team |
| Review and update runbook | Quarterly | Engineering Lead |

---

## Access & Permissions (存取與權限)

### Production Server Access:

- **SSH Access**: Engineers with approved SSH keys
- **Git Access**: Engineers with Jasslin GitHub org membership
- **Docker Commands**: All engineers (no sudo required)

### Documentation Access:

- **Read**: All Jasslin employees
- **Write**: Engineers assigned to service
- **Approve Changes**: Engineering Lead

---

## Contact Information (聯絡資訊)

### For Operational Issues:

| Role | Name | Contact |
|------|------|---------|
| **Engineering Lead** | [Name] | [Email/Phone] |
| **Flemabus On-Call** | Ezra Wu (吳豐吉) | [Email/Phone] |
| **Infrastructure** | [Name] | [Email/Phone] |

### For Policy Questions:

- See: `/RELEASE_POLICY.md`
- Contact: Engineering Lead

---

## Document Maintenance (文檔維護)

### Updating This Index:

1. Each service maintains its own 4 documentation files
2. This index only tracks **locations and metadata**
3. When adding/removing services, update this file
4. Submit PR to `documentation-management` repository

### Version History:

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2026-02-02 | Initial version with Flemabus | Ezra Wu |

---

**END OF INDEX**

**For release procedures**, see: `/RELEASE_POLICY.md`  
**For documentation templates**, see: `/templates/docs/`
