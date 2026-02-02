# System Facts Checklist
# 系統事實檢核清單

**Project**: _____________  
**Version**: _____________  
**Deployment Date**: _____________  
**Completed By**: _____________

---

## Purpose (目的)

**This checklist documents the ACTUAL system state, not assumptions.**  
**本檢核清單記錄實際系統狀態，而非假設。**

**Why this exists:**  
In the 2-week outage incident, vendors didn't know:
- How many database instances existed (4, not 1)
- Which services connected to which databases
- Network topology and dependencies
- Actual port usage

**This caused:**
- Incorrect troubleshooting
- Wrong recovery attempts
- Extended downtime

**Solution: Document system facts. No facts = No acceptance.**  
**解決方案：記錄系統事實。沒有事實 = 不接受交付。**

---

## ✅ MANDATORY: Must Complete Before Deployment

**This checklist MUST be filled out completely before any production deployment.**  
**本檢核清單必須在任何生產部署前完整填寫。**

**Incomplete checklist = Deployment BLOCKED.**  
**檢核清單不完整 = 部署被阻止。**

---

## Section 1: Database Instances (資料庫實例)

### Database #1

**Instance Name / Hostname**:  
□ _____________________________________________

**Purpose / Used By**:  
□ _____________________________________________

**Connection Sources** (which services connect to this DB):  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)

**Port**:  
□ _____________

**Docker Network**:  
□ _____________________________________________

**Data Volume Path**:  
□ _____________________________________________

**Backup Location**:  
□ _____________________________________________

---

### Database #2

**Instance Name / Hostname**:  
□ _____________________________________________

**Purpose / Used By**:  
□ _____________________________________________

**Connection Sources** (which services connect to this DB):  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)

**Port**:  
□ _____________

**Docker Network**:  
□ _____________________________________________

**Data Volume Path**:  
□ _____________________________________________

**Backup Location**:  
□ _____________________________________________

---

### Database #3

**Instance Name / Hostname**:  
□ _____________________________________________

**Purpose / Used By**:  
□ _____________________________________________

**Connection Sources** (which services connect to this DB):  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)

**Port**:  
□ _____________

**Docker Network**:  
□ _____________________________________________

**Data Volume Path**:  
□ _____________________________________________

**Backup Location**:  
□ _____________________________________________

---

### Database #4

**Instance Name / Hostname**:  
□ _____________________________________________

**Purpose / Used By**:  
□ _____________________________________________

**Connection Sources** (which services connect to this DB):  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)  
□ Service: _____________ (container name: _____________)

**Port**:  
□ _____________

**Docker Network**:  
□ _____________________________________________

**Data Volume Path**:  
□ _____________________________________________

**Backup Location**:  
□ _____________________________________________

---

### Database Instances Summary

**Total number of database instances**: □ _______

**If different from 4, explain**:  
_____________________________________________  
_____________________________________________

---

## Section 2: Service Inventory (服務清單)

### Service #1

**Service Name**:  
□ _____________________________________________

**Container Name** (must include project prefix):  
□ _____________________________________________

**Purpose**:  
□ _____________________________________________

**Port Mappings** (host:container):  
□ _____________:_____________  
□ _____________:_____________

**Docker Network(s)**:  
□ _____________________________________________

**Dependencies** (which other services does this depend on):  
□ _____________________________________________  
□ _____________________________________________

**Database Connections** (which DB instances):  
□ Database #_____ (_____________)  
□ Database #_____ (_____________)

**Health Check Endpoint**:  
□ _____________________________________________

---

### Service #2

**Service Name**:  
□ _____________________________________________

**Container Name** (must include project prefix):  
□ _____________________________________________

**Purpose**:  
□ _____________________________________________

**Port Mappings** (host:container):  
□ _____________:_____________  
□ _____________:_____________

**Docker Network(s)**:  
□ _____________________________________________

**Dependencies** (which other services does this depend on):  
□ _____________________________________________  
□ _____________________________________________

**Database Connections** (which DB instances):  
□ Database #_____ (_____________)  
□ Database #_____ (_____________)

**Health Check Endpoint**:  
□ _____________________________________________

---

### Service #3

**Service Name**:  
□ _____________________________________________

**Container Name** (must include project prefix):  
□ _____________________________________________

**Purpose**:  
□ _____________________________________________

**Port Mappings** (host:container):  
□ _____________:_____________  
□ _____________:_____________

**Docker Network(s)**:  
□ _____________________________________________

**Dependencies** (which other services does this depend on):  
□ _____________________________________________  
□ _____________________________________________

**Database Connections** (which DB instances):  
□ Database #_____ (_____________)  
□ Database #_____ (_____________)

**Health Check Endpoint**:  
□ _____________________________________________

---

*Add more services as needed*

---

## Section 3: Network Topology (網路拓撲)

### Network #1

**Network Name** (must include project prefix):  
□ _____________________________________________

**Driver**:  
□ bridge  □ overlay  □ host  □ other: _____________

**Connected Services**:  
□ _____________________________________________  
□ _____________________________________________  
□ _____________________________________________

**Subnet** (if custom):  
□ _____________________________________________

**Gateway**:  
□ _____________________________________________

---

### Network #2

**Network Name** (must include project prefix):  
□ _____________________________________________

**Driver**:  
□ bridge  □ overlay  □ host  □ other: _____________

**Connected Services**:  
□ _____________________________________________  
□ _____________________________________________  
□ _____________________________________________

**Subnet** (if custom):  
□ _____________________________________________

**Gateway**:  
□ _____________________________________________

---

### Network Isolation Verification

□ **Confirmed**: No services use default Docker network  
□ **Confirmed**: All network names include project prefix  
□ **Confirmed**: No network name conflicts with other projects

---

## Section 4: Port Allocation (端口分配)

### Port Usage Table

| Port | Service Name | Container Name | Purpose | Conflict Check |
|------|-------------|----------------|---------|----------------|
| _____ | __________ | _____________ | _______ | □ No conflict |
| _____ | __________ | _____________ | _______ | □ No conflict |
| _____ | __________ | _____________ | _______ | □ No conflict |
| _____ | __________ | _____________ | _______ | □ No conflict |
| _____ | __________ | _____________ | _______ | □ No conflict |

### Port Conflict Verification

**Command run**:  
```bash
netstat -tlnp | grep <port>
# Or: ss -tlnp | grep <port>
```

**Results**:  
□ All ports verified available  
□ No port conflicts detected

**If conflicts found, resolution**:  
_____________________________________________  
_____________________________________________

---

## Section 5: Volume Mounts & Data Persistence (卷掛載與數據持久化)

### Volume #1

**Volume Name / Path**:  
□ _____________________________________________

**Type**:  
□ Named volume  □ Bind mount  □ tmpfs

**Used By** (service name):  
□ _____________________________________________

**Purpose** (what data is stored):  
□ _____________________________________________

**Backup Strategy**:  
□ _____________________________________________

**Verified Writable**:  
□ Yes  □ No

---

### Volume #2

**Volume Name / Path**:  
□ _____________________________________________

**Type**:  
□ Named volume  □ Bind mount  □ tmpfs

**Used By** (service name):  
□ _____________________________________________

**Purpose** (what data is stored):  
□ _____________________________________________

**Backup Strategy**:  
□ _____________________________________________

**Verified Writable**:  
□ Yes  □ No

---

*Add more volumes as needed*

---

## Section 6: External Dependencies (外部依賴)

### 3rd-Party API #1

**Service Name**:  
□ _____________________________________________

**API Endpoint**:  
□ _____________________________________________

**Used By** (which service(s)):  
□ _____________________________________________

**Authentication Method**:  
□ API Key  □ OAuth  □ JWT  □ Other: _____________

**Environment Variable Name**:  
□ _____________________________________________

**Failure Impact** (what breaks if this API is down):  
□ _____________________________________________

---

### 3rd-Party API #2

**Service Name**:  
□ _____________________________________________

**API Endpoint**:  
□ _____________________________________________

**Used By** (which service(s)):  
□ _____________________________________________

**Authentication Method**:  
□ API Key  □ OAuth  □ JWT  □ Other: _____________

**Environment Variable Name**:  
□ _____________________________________________

**Failure Impact** (what breaks if this API is down):  
□ _____________________________________________

---

*Add more APIs as needed*

---

## Section 7: Environment Variables (環境變數)

**Total number of required environment variables**: □ _______

**Environment variables checklist**:

□ DATABASE_URL(s) - defined for each DB instance  
□ API keys for external services  
□ JWT/session secrets  
□ Service URLs (if microservices)  
□ Log level configuration  
□ Feature flags (if any)  
□ Other: _____________________________________________

**Location of .env.example**:  
□ _____________________________________________

**Verified**: All variables in .env.example are documented with descriptions:  
□ Yes  □ No

---

## Section 8: Deployment Verification (部署驗證)

### Pre-Deployment Checks

□ All services start successfully  
□ All health check endpoints return 200 OK  
□ Database connections verified (all services can connect to their DBs)  
□ Network connectivity verified (services can communicate)  
□ Port conflicts resolved  
□ Volume permissions verified (containers can write)  
□ Logs show no errors on startup

### Post-Deployment Checks

□ All containers running (`docker-compose ps` all "Up")  
□ No restart loops (uptime > 5 minutes)  
□ Application responds to HTTP requests  
□ Database queries succeed  
□ No error logs in last 5 minutes  
□ Health checks passing for 5+ minutes

---

## Section 9: Rollback Information (回滾資訊)

### Previous Known-Good Version

**Git Tag**:  
□ _____________________________________________

**Deployment Date**:  
□ _____________________________________________

**Verified Working**:  
□ Yes  □ No

**Rollback Command**:  
```bash
git checkout <previous-tag>
docker-compose up -d
```

### Rollback Test

**Rollback tested in staging**:  
□ Yes  □ No

**Rollback time** (from decision to services up):  
□ _______ seconds/minutes

**Rollback succeeded**:  
□ Yes  □ No

---

## Section 10: System Facts Summary (系統事實摘要)

### Critical Numbers

- Total databases: □ _______
- Total services: □ _______
- Total Docker networks: □ _______
- Total ports used: □ _______
- Total volumes: □ _______
- Total external APIs: □ _______

### Topology Diagram

**Mermaid diagram included in ARCHITECTURE.md**:  
□ Yes  □ No

**Diagram shows**:  
□ All database instances  
□ All services  
□ All network connections  
□ All external dependencies

---

## Section 11: Knowledge Verification (知識驗證)

### Team Knowledge Check

**Question**: How many database instances does this system have?  
**Answer**: □ _______

**Question**: If API service goes down, which other services are affected?  
**Answer**: _____________________________________________

**Question**: What is the rollback procedure?  
**Answer**: _____________________________________________

**Question**: Which service connects to Database #3?  
**Answer**: _____________________________________________

### Documentation Completeness

□ All 4 documentation files completed (ARCHITECTURE, DEPLOY, RESILIENCE, TEST_REPORT)  
□ All sections of this checklist filled out  
□ No "TBD" or placeholder values  
□ All checkboxes checked or explicitly marked N/A

---

## Section 12: Sign-Off (簽核)

### Vendor Sign-Off

**I confirm that:**
- All information in this checklist is accurate and complete
- I have tested the deployment in staging
- I understand the system topology
- I have documented all dependencies
- I have verified all database connections
- I have tested the rollback procedure

**Name**: _____________________________________________  
**Role**: _____________________________________________  
**Signature**: _____________________________________________  
**Date**: _____________________________________________

---

### Jasslin Engineering Review

**Reviewed by**: _____________________________________________  
**Date**: _____________________________________________  
**Approval**: □ Approved  □ Rejected

**If rejected, reason**:  
_____________________________________________  
_____________________________________________

---

## ⚠️ CRITICAL RULE

**Incomplete checklist = Deployment BLOCKED**

If any section is incomplete or contains placeholder values:
- Deployment will NOT be accepted
- PR will NOT be merged
- Payment will NOT be released

**No exceptions.**

---

## Usage Instructions (使用說明)

### For Vendors

1. **Copy this template** for each deployment
2. **Fill out completely** (no placeholders, no "TBD")
3. **Verify all facts** by actually checking the system
4. **Test rollback** in staging before production
5. **Submit with PR** as `docs/SYSTEM_FACTS.md`
6. **Wait for review** before deployment

### For Jasslin Engineering

1. **Review completeness** (all checkboxes, no blanks)
2. **Verify facts** (spot-check actual system state)
3. **Test knowledge** (ask vendor about topology)
4. **Approve or reject** with clear feedback
5. **Store in docs** for future reference

---

**This checklist prevents:**
- "I didn't know there were 4 databases"
- "I thought it was using the default network"
- "I didn't know service X depends on service Y"
- "I couldn't find the previous working version"

**System facts, not assumptions. No facts = No deployment.**
