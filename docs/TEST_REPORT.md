# TEST REPORT 測試報告

## Staging Environment Verification (預發環境驗證)

### Environment Information (環境資訊)

| Field | Value |
|-------|-------|
| **Environment** | Staging / Pre-Production |
| **Server IP/Hostname** | `staging.example.com` / `192.168.1.100` |
| **Docker Version** | `24.0.7` |
| **Docker Compose Version** | `v2.21.0` |
| **OS Version** | `Ubuntu 22.04.3 LTS` |
| **Kernel Version** | `5.15.0-91-generic` |
| **Deployment Date** | 2026-02-02 |
| **Git Commit Hash** | `abc123def456` |
| **Git Tag/Release** | `v1.2.3` |

---

## Pre-Deployment Checklist (部署前檢查清單)

| Check Item | Status | Notes | Verified By | Date |
|------------|--------|-------|-------------|------|
| Docker service enabled on boot | ✅ Pass / ❌ Fail | `systemctl is-enabled docker` = enabled | | |
| All services have `restart: always` | ✅ Pass / ❌ Fail | Verified in `docker-compose.yml` | | |
| Health checks configured | ✅ Pass / ❌ Fail | All critical services have healthcheck | | |
| `.env` file validated | ✅ Pass / ❌ Fail | No syntax errors, all secrets set | | |
| Volume permissions correct | ✅ Pass / ❌ Fail | PostgreSQL: 999:999, Redis: 999:999 | | |
| Firewall rules configured | ✅ Pass / ❌ Fail | Only 80/443 exposed, SSH restricted | | |
| SSL certificates valid | ✅ Pass / ❌ Fail | Not expired, auto-renewal configured | | |
| Backup strategy in place | ✅ Pass / ❌ Fail | Automated backups scheduled | | |

---

## Hard Reboot Test (硬重啟測試)

### ⚠️ MANDATORY REQUIREMENT (強制要求)

**This test MUST be performed on staging before production deployment.**

A hard reboot test simulates a server crash or power failure. All services must automatically restart without manual intervention.

### Test Procedure (測試程序)

```bash
# 1. Record current state
docker-compose ps > /tmp/pre-reboot-state.txt
docker stats --no-stream > /tmp/pre-reboot-stats.txt

# 2. Perform hard reboot (simulates power failure)
sudo reboot now

# 3. Wait for server to come back online (usually 2-5 minutes)
# SSH back into the server

# 4. Verify Docker started automatically
systemctl status docker.service
# Expected: Active: active (running)

# 5. Wait for containers to start (2-3 minutes)
sleep 180

# 6. Check all containers are running
docker-compose ps
# All containers should show "Up" status

# 7. Verify health checks
docker-compose ps | grep -i "healthy"

# 8. Check application endpoints
curl -f http://localhost:8080/health
curl -f http://localhost:8081/auth/health

# 9. Compare pre/post reboot state
docker-compose ps > /tmp/post-reboot-state.txt
diff /tmp/pre-reboot-state.txt /tmp/post-reboot-state.txt
```

### Hard Reboot Test Checklist (硬重啟測試清單)

| Test Item | Expected Result | Actual Result | Pass/Fail | Logs/Screenshot | Notes |
|-----------|-----------------|---------------|-----------|-----------------|-------|
| **Server boots successfully** | Server comes online within 5 minutes | | ✅ / ❌ | | |
| **Docker service auto-starts** | `systemctl status docker` shows "active (running)" | | ✅ / ❌ | | |
| **All containers start automatically** | `docker ps` shows all containers "Up" | | ✅ / ❌ | | |
| **No manual intervention required** | No need to run `docker-compose up` | | ✅ / ❌ | | |
| **Health checks pass** | All health checks return healthy status | | ✅ / ❌ | | |
| **API endpoints responsive** | `/health` endpoints return 200 OK | | ✅ / ❌ | | |
| **Database connections work** | Application can query database | | ✅ / ❌ | | |
| **Redis connections work** | Application can access cache | | ✅ / ❌ | | |
| **Logs are being written** | New logs appear in `/opt/app/logs` | | ✅ / ❌ | | |
| **User authentication works** | Users can log in successfully | | ✅ / ❌ | | |
| **End-to-end test passes** | Critical user flow completes | | ✅ / ❌ | | |

### Test Execution Details (測試執行詳情)

| Field | Value |
|-------|-------|
| **Test Date** | YYYY-MM-DD |
| **Test Time** | HH:MM (timezone) |
| **Performed By** | Name / Team |
| **Reboot Duration** | X minutes Y seconds |
| **Time to All Services Up** | X minutes Y seconds |
| **Total Downtime** | X minutes Y seconds |
| **Incident?** | Yes / No |

### Test Result Summary (測試結果摘要)

```
Overall Status: ✅ PASS / ❌ FAIL

Total Checks: X
Passed: X
Failed: X
Warnings: X

Critical Issues Found:
- [List any critical issues]

Recommendations:
- [List any recommendations]
```

### Evidence (證據)

**Screenshots/Logs to attach:**
- [ ] Pre-reboot `docker-compose ps` output
- [ ] Post-reboot `docker-compose ps` output
- [ ] `systemctl status docker.service` output
- [ ] Application logs during startup
- [ ] Health check endpoint responses
- [ ] Monitoring dashboard during reboot period

---

## Functional Test Results (功能測試結果)

### API Endpoint Tests (API 端點測試)

| Endpoint | Method | Expected Status | Actual Status | Response Time | Pass/Fail | Notes |
|----------|--------|-----------------|---------------|---------------|-----------|-------|
| `/health` | GET | 200 | | | ✅ / ❌ | |
| `/api/users` | GET | 200 | | | ✅ / ❌ | Requires auth |
| `/api/users` | POST | 201 | | | ✅ / ❌ | Create user |
| `/auth/login` | POST | 200 | | | ✅ / ❌ | Returns JWT |
| `/auth/refresh` | POST | 200 | | | ✅ / ❌ | Token refresh |
| `/api/upload` | POST | 200 | | | ✅ / ❌ | File upload |

### Performance Tests (效能測試)

| Test Type | Tool | Duration | Concurrent Users | Requests/sec | Avg Response Time | 95th Percentile | Error Rate | Pass/Fail |
|-----------|------|----------|------------------|--------------|-------------------|-----------------|------------|-----------|
| Load Test | Apache Bench / k6 | 5 min | 100 | | | | | ✅ / ❌ |
| Stress Test | k6 | 10 min | 500 | | | | | ✅ / ❌ |
| Spike Test | k6 | 2 min | 1000 | | | | | ✅ / ❌ |

### Database Tests (資料庫測試)

| Test Case | Expected Behavior | Actual Result | Pass/Fail | Notes |
|-----------|-------------------|---------------|-----------|-------|
| Connection pooling | Max 10 connections, reused efficiently | | ✅ / ❌ | |
| Transaction rollback | Failed transactions rollback completely | | ✅ / ❌ | |
| Concurrent writes | No deadlocks under load | | ✅ / ❌ | |
| Migration idempotency | Re-running migrations is safe | | ✅ / ❌ | |
| Backup & restore | Restore from backup works correctly | | ✅ / ❌ | |

### Security Tests (安全測試)

| Test Case | Expected Behavior | Actual Result | Pass/Fail | Notes |
|-----------|-------------------|---------------|-----------|-------|
| SQL injection | Blocked by parameterized queries | | ✅ / ❌ | |
| XSS protection | Input sanitized, CSP headers set | | ✅ / ❌ | |
| JWT validation | Invalid tokens rejected | | ✅ / ❌ | |
| Rate limiting | Excessive requests blocked | | ✅ / ❌ | |
| HTTPS enforcement | HTTP redirects to HTTPS | | ✅ / ❌ | |
| Secret exposure | No secrets in logs or responses | | ✅ / ❌ | |

---

## Rollback Plan (回滾計劃)

### When to Rollback (何時回滾)

Initiate rollback if any of the following conditions are met:
- ❌ Hard reboot test fails
- ❌ Critical functionality broken
- ❌ Data corruption detected
- ❌ Unresolvable errors in production
- ❌ Performance degradation > 50%

### Rollback Procedure (回滾程序)

#### Method 1: Git Tag Rollback (推薦)

**Prerequisites**: Previous version tagged in Git (e.g., `v1.2.2`)

```bash
# 1. Stop current services
cd /opt/app
docker-compose down

# 2. List available tags
git tag -l

# 3. Checkout previous stable version
git fetch --all --tags
git checkout tags/v1.2.2 -b rollback-v1.2.2

# 4. Verify correct version
git log -1 --oneline
# Expected: Shows commit for v1.2.2

# 5. Rebuild images (if needed)
docker-compose build --no-cache

# 6. Start services
docker-compose up -d

# 7. Verify rollback success
sleep 60
docker-compose ps
curl -f http://localhost:8080/health

# 8. Monitor logs for errors
docker-compose logs -f --tail=100
```

#### Method 2: Docker Image Tag Rollback (快速回滾)

**Prerequisites**: Previous Docker images still available in registry

```bash
# 1. Stop current services
docker-compose down

# 2. Update docker-compose.yml to use previous image tag
sed -i 's/:latest/:v1.2.2/g' docker-compose.yml

# Or manually edit:
# api-service:
#   image: your-org/api-service:v1.2.2  # Change from :latest

# 3. Pull previous images
docker-compose pull

# 4. Start services
docker-compose up -d

# 5. Verify rollback
docker-compose ps
curl -f http://localhost:8080/health
```

#### Method 3: Database Rollback (資料庫回滾)

**⚠️ CAUTION**: Only if database schema changed in the failed deployment.

```bash
# 1. Stop all services
docker-compose down

# 2. Restore database from backup
BACKUP_FILE="/opt/app/backups/postgres_backup_2026-02-01_20-00.sql"

docker-compose up -d postgres
sleep 30

# Drop and recreate database
docker-compose exec postgres psql -U app_user -d postgres -c "DROP DATABASE IF EXISTS app_production;"
docker-compose exec postgres psql -U app_user -d postgres -c "CREATE DATABASE app_production;"

# Restore from backup
docker-compose exec -T postgres psql -U app_user -d app_production < "$BACKUP_FILE"

# 3. Verify restoration
docker-compose exec postgres psql -U app_user -d app_production -c "\dt"

# 4. Start all services
docker-compose up -d
```

### Rollback Verification Checklist (回滾驗證清單)

- [ ] Services are running (`docker-compose ps`)
- [ ] Health checks pass
- [ ] Database connections work
- [ ] Critical user flows work
- [ ] No errors in logs
- [ ] Performance is normal
- [ ] Monitoring dashboards show healthy metrics
- [ ] Notify team that rollback is complete

### Post-Rollback Actions (回滾後行動)

```bash
# 1. Create incident report
cat > /opt/app/incidents/incident-$(date +%Y%m%d).md <<EOF
# Incident Report

Date: $(date)
Deployment Version: v1.2.3 (failed)
Rollback Version: v1.2.2
Root Cause: [To be investigated]
Impact: [Describe impact]
Resolution: Rolled back to previous stable version

Next Steps:
- [ ] Investigate root cause
- [ ] Fix issues in development
- [ ] Test thoroughly in staging
- [ ] Schedule re-deployment
EOF

# 2. Preserve logs for investigation
docker-compose logs > /opt/app/incidents/failed-deployment-logs-$(date +%Y%m%d).log

# 3. Notify stakeholders
# [Send notification via your communication channel]
```

---

## Acceptance Criteria (驗收標準)

### ✅ Deployment is ACCEPTED if:

1. **All pre-deployment checks pass**
2. **Hard reboot test passes without manual intervention**
3. **All functional tests pass**
4. **Performance meets SLA requirements**
5. **No critical or high severity security issues**
6. **Documentation is complete and accurate**
7. **Rollback plan tested and verified**

### ❌ Deployment is REJECTED if:

1. **Docker service not enabled for auto-start**
2. **Any service missing `restart: always`**
3. **Hard reboot test fails**
4. **Critical functionality broken**
5. **Performance degrades significantly**
6. **Security vulnerabilities introduced**
7. **Documentation incomplete or missing**

---

## Sign-Off (簽核)

| Role | Name | Signature | Date | Approval |
|------|------|-----------|------|----------|
| **DevOps Engineer** | | | | ✅ Approved / ❌ Rejected |
| **QA Lead** | | | | ✅ Approved / ❌ Rejected |
| **Backend Lead** | | | | ✅ Approved / ❌ Rejected |
| **Product Manager** | | | | ✅ Approved / ❌ Rejected |

### Final Approval (最終批准)

- [ ] All tests passed
- [ ] All stakeholders approved
- [ ] Documentation complete
- [ ] Ready for production deployment

**Approved for Production**: ✅ YES / ❌ NO

**Approval Date**: YYYY-MM-DD  
**Scheduled Production Deployment**: YYYY-MM-DD HH:MM  
**Responsible Engineer**: [Name]

---

**Document Version**: 1.0  
**Last Updated**: 2026-02-02  
**Maintained By**: QA & DevOps Team  
**Review Cycle**: After every staging deployment
