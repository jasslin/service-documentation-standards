# Production Release Policy
# 生產環境釋出政策

**Effective Date**: February 2026  
**Authorized By**: Epaphras (吳豐吉), Engineer  
**Authority**: Jasslin Engineering Team

**Version**: 1.0.0  
**Last Updated**: 2026-02-02

---

## Purpose (目的)

This policy defines the **mandatory technical requirements** for deploying services to production.

These requirements exist because of the **2-week Flemabus outage incident** where:
- Network conflicts broke both production and test systems
- Accidental `docker-compose down` in wrong directory
- No rollback capability (recovery took 2 weeks)
- Knowledge existed only in one engineer's memory

**This policy prevents those failures from recurring.**  
**本政策防止這些失誤再次發生。**

---

## Release Entry Point (釋出入口)

### All Production Deployments MUST:

1. **Submit Pull Request** to the service's git repository
2. **Pass Hard Gate Validation** (automated checks)
3. **Obtain Approval** from authorized engineer
4. **Deploy via git tag** (never manual docker-compose commands)

### Workflow:

```bash
# 1. Create branch and make changes
git checkout -b release/v1.2.3

# 2. Run validation before PR
bash scripts/validate-hardgates.sh

# 3. Submit PR
# (CI/CD runs validation automatically)

# 4. After approval, tag and deploy
git tag -a v1.2.3 -m "Production release"
git push origin v1.2.3

# 5. On production server
cd /opt/[service-name]
git fetch --tags
git checkout v1.2.3
docker-compose up -d
```

---

## Mandatory Hard Gates (必過閘門)

**Pull requests will be BLOCKED if any check fails.**  
**如果任何檢查失敗，拉取請求將被阻止。**

### Gate #1: Environment Isolation (環境隔離)

**Prevents**: Network conflicts that break multiple systems

**Checks**:
- ❌ Generic network names (app-network, default, web, backend)
- ❌ Missing container_name with project prefix  
- ❌ No custom network definition

**Required**:
```yaml
services:
  api:
    container_name: projectname-api  # Project-specific
    networks:
      - projectname-network

networks:
  projectname-network:  # Explicitly defined
    driver: bridge
```

---

### Gate #2: Git-Tracked Configuration (配置追蹤)

**Prevents**: Accidental docker-compose down in wrong directory

**Checks**:
- ❌ docker-compose.yml not tracked in git
- ❌ Missing PROJECT_NAME in .env

**Required**:
```bash
# docker-compose.yml must be in git
git ls-files docker-compose.yml

# .env must define project
PROJECT_NAME=projectname
```

---

### Gate #3: Rollback Capability (回滾能力)

**Prevents**: 2-week recovery time when things break

**Checks**:
- ❌ Untagged git commits
- ❌ Tag format not v1.0.0

**Required**:
```bash
# Every production deployment must be tagged
git tag -a v1.2.3 -m "Production release"

# Format: v[major].[minor].[patch]
# Examples: v1.0.0, v2.3.1
```

**Rollback procedure**:
```bash
# Instant rollback to previous version
git checkout v1.2.2
docker-compose up -d
```

---

### Gate #4: Service Persistence (服務持久性)

**Prevents**: Manual restart required after server reboot

**Checks**:
- ❌ Missing `restart: always`
- ❌ No healthcheck configuration

**Required**:
```yaml
services:
  api:
    restart: always  # Must be present
    healthcheck:      # Must be present
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

### Gate #5: Documentation (文件記錄)

**Prevents**: Knowledge single-point-of-failure (only one person can fix issues)

**Checks**:
- ❌ Missing docs/ARCHITECTURE.md
- ❌ Missing docs/DEPLOY.md
- ❌ Missing docs/RESILIENCE.md
- ❌ Missing docs/TEST_REPORT.md

**Templates available at**: `/templates/docs/` in this repository

---

## Automated Validation (自動化驗證)

**Run before submitting PR:**

```bash
bash scripts/validate-hardgates.sh
```

**This script checks all 5 gates automatically.**  
**CI/CD pipeline runs this script on every pull request.**

If validation fails:
- Fix the issues
- Re-run validation
- Submit PR only after all checks pass

---

## Approval Authority (批准權限)

### Who Can Approve Production Releases:

1. **Engineering Lead** - Full authority
2. **Senior Engineers** - For their assigned services
3. **On-Call Engineer** - Emergency hotfixes only

### Approval Requirements:

- ✅ All Hard Gates passed (automated validation)
- ✅ Code review completed
- ✅ Changes documented in release notes

### What Approvers Verify:

1. **Validation passed**: Green checkmark from CI/CD
2. **Documentation complete**: 4 docs files updated
3. **Rollback plan**: Previous git tag identified
4. **Impact assessment**: Which services affected

**Approvers do NOT need to manually verify technical details** — automation handles that.  
**批准者不需要手動驗證技術細節** — 自動化處理這些。

---

## Rejection Conditions (拒絕條件)

**Pull requests WILL BE REJECTED if:**

### Automatic Rejections (by CI/CD):

- ❌ Hard Gate validation failed
- ❌ Build/compilation failed
- ❌ Syntax errors in docker-compose.yml

### Manual Rejections (by Approver):

- ❌ Documentation is empty or placeholder-only
- ❌ No rollback plan identified
- ❌ Changes not explained in PR description
- ❌ Violates existing architecture without discussion

### Emergency Override:

In **critical production outage** only:
- On-call engineer can bypass documentation requirement
- MUST create follow-up PR with documentation within 24 hours
- Requires Engineering Lead sign-off retroactively

---

## What Happens When Gates Fail (閘門失敗時會發生什麼)

### Before Merge:
- CI/CD pipeline fails
- Red X appears on pull request
- Cannot merge until fixed

### During Release:
- If validation fails on production server
- **DO NOT PROCEED**
- Roll back to previous tagged version
- Fix issues in development environment first

### After Deployment:
If issues discovered:
```bash
# Immediate rollback
git checkout v[previous-version]
docker-compose up -d

# Create incident report
# Fix issues
# Re-submit as new release
```

---

## Quick Reference Card (快速參考卡)

**Before submitting ANY production change:**

```bash
# 1. Validate
bash scripts/validate-hardgates.sh

# 2. Check output
✓ Environment isolation
✓ Git tracking  
✓ Version tagged
✓ Service persistence
✓ Documentation

# 3. If all pass → Submit PR
# 4. If any fail → Fix first
```

**Questions?** See `/OPS_RUNBOOK.md` for links to detailed documentation.

---

## Policy Enforcement (政策執行)

This policy is enforced through:

1. **Automated validation** — Cannot bypass CI/CD checks
2. **PR approval required** — No direct commits to main/master
3. **Git tag requirement** — Production servers only accept tagged versions
4. **Audit trail** — All deployments logged with git history

**These are technical controls, not trust-based policies.**  
**這些是技術控制，而非基於信任的政策。**

---

## History & Context (歷史與背景)

**Why this policy exists:**

In January 2026, the Flemabus production service experienced **2-week complete outage** due to:
- Network naming conflicts
- Accidental docker-compose down
- No rollback capability
- Knowledge concentrated in one person

**Impact**:
- 2 weeks of zero service availability
- Client business completely stopped
- Recovery required reverse-engineering everything from memory

**The 5 Hard Gates directly address these root causes.**  
**5個硬性閘門直接針對這些根本原因。**

Full incident details: See README.md "The Incident" section

---

**END OF POLICY**

**For operational procedures**, see: `/OPS_RUNBOOK.md`  
**For documentation templates**, see: `/templates/docs/`
