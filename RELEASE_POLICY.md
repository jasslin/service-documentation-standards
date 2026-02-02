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

---

### Gate #1: Merge Control (合併控制) 🔴 **MOST IMPORTANT**

**Prevents**: Unauthorized or untested changes reaching production

**This is the enforcement mechanism for ALL other gates.**  
**這是所有其他閘門的執行機制。**

#### 1.1 Branch Protection (分支保護)

**Configuration** (on GitHub/GitLab):

```yaml
# Branch: main, release/*
Settings:
  - Require pull request before merging: ✅ YES
  - Require status checks to pass: ✅ YES
    - validate-hardgates (CI job)
  - Require review from CODEOWNERS: ✅ YES
  - Do not allow bypassing: ✅ YES (no admin override)
  - Require signed commits: ✅ YES (recommended)
```

**Result**: Cannot push directly to main. Cannot merge without CI green + approvals.  
**結果**：無法直接推送到 main。無法在 CI 綠燈 + 批准前合併。

#### 1.2 CODEOWNERS (程式碼所有權)

**Create `.github/CODEOWNERS` in service repository:**

```bash
# Infrastructure & Deployment - MUST be approved by Ezra Wu
# 基礎設施與部署 - 必須由 Ezra Wu 批准

# Docker & Container Configuration
docker-compose*.yml          @ezra-wu
Dockerfile*                  @ezra-wu
.dockerignore               @ezra-wu

# Environment & Secrets
.env*                       @ezra-wu
*.env                       @ezra-wu
config/*.env                @ezra-wu

# Database Migrations & Schema
migrations/                 @ezra-wu
schema/                     @ezra-wu
**/migrations/             @ezra-wu
*.sql                      @ezra-wu

# Infrastructure as Code
terraform/                  @ezra-wu
*.tf                       @ezra-wu
k8s/                       @ezra-wu
*.yaml                     @ezra-wu

# Deployment Scripts
scripts/deploy*.sh         @ezra-wu
scripts/rollback*.sh       @ezra-wu
deploy/                    @ezra-wu

# CI/CD Pipeline
.github/workflows/         @ezra-wu
.gitlab-ci.yml            @ezra-wu
Jenkinsfile               @ezra-wu

# Documentation (Deployment-related)
docs/DEPLOY.md            @ezra-wu
docs/RESILIENCE.md        @ezra-wu
docs/ARCHITECTURE.md      @ezra-wu
```

**Result**: Changes to these files CANNOT be merged without your explicit approval.  
**結果**：這些檔案的變更無法在沒有你明確批准的情況下合併。

#### 1.3 CI/CD Validation (自動化驗證)

**Create `.github/workflows/validate.yml`:**

```yaml
name: Hard Gates Validation

on:
  pull_request:
    branches: [main, release/*]
  push:
    branches: [main, release/*]

jobs:
  validate-hardgates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Hard Gates Check
        run: |
          curl -O https://raw.githubusercontent.com/jasslin/documentation-management/main/scripts/validate-hardgates.sh
          chmod +x validate-hardgates.sh
          bash validate-hardgates.sh
      
      - name: Block merge if validation fails
        if: failure()
        run: |
          echo "❌ Hard Gates validation FAILED"
          echo "Pull request CANNOT be merged"
          exit 1
```

**Result**: Red X on PR if validation fails. Cannot merge.  
**結果**：驗證失敗則 PR 顯示紅 X。無法合併。

#### 1.4 Why This Works (為何有效)

**Before (failed approach):**
- ❌ Trust-based: "Please follow best practices"
- ❌ Optional: Engineers can ignore guidelines
- ❌ No enforcement: Reviews are subjective

**After (technical control):**
- ✅ **Cannot merge** without CI green
- ✅ **Cannot merge** without your approval (for infra changes)
- ✅ **Cannot bypass** (no admin override)
- ✅ **Automated** (no manual checking needed)

**You don't need to ask them to "be transparent."**  
**Technical controls enforce transparency automatically.**  
**你不需要求他們「願意透明」。技術控制自動強制透明。**

---

### Gate #2: Automated Release Pipeline (自動化釋出管道) 🔴 **PREVENTS MANUAL SSH OPERATIONS**

**Prevents**: Manual SSH operations that caused 2-week outage (accidental docker-compose down)

**The Problem This Solves:**  
In the incident, engineer manually SSH'd to production and ran `docker-compose down` in wrong directory, bringing down production for 2 weeks.

**Solution: Production releases MUST go through automated pipeline. Manual SSH operations are FORBIDDEN.**  
**解決方案：生產釋出必須通過自動化管道。禁止手動 SSH 操作。**

#### 2.1 Deployment Method (部署方式)

**✅ ONLY ALLOWED:**
```bash
# On your local machine:
git tag -a v1.2.3 -m "Production release"
git push origin v1.2.3

# GitHub Actions pipeline automatically:
# 1. Validates all hard gates
# 2. Builds and pushes Docker images
# 3. Creates deployment artifact (snapshot)
# 4. SSHs to production server
# 5. Deploys using the artifact
# 6. Verifies health checks
# 7. Stores rollback snapshot
```

**❌ FORBIDDEN:**
```bash
# Manual SSH operations are FORBIDDEN:
ssh production-server
cd /opt/service
docker-compose down     # ❌ FORBIDDEN - caused 2-week outage
docker-compose up -d    # ❌ FORBIDDEN - must use pipeline
vim docker-compose.yml  # ❌ FORBIDDEN - must go through git
docker-compose pull     # ❌ FORBIDDEN - must use pipeline
```

#### 2.2 Required Pipeline Configuration

**Create `.github/workflows/deploy-production.yml`:**

Pipeline MUST:
- Only trigger on git tags (v*.*.*)
- Run all hard gate validations
- Build images with digest pinning
- Create deployment snapshot (artifact)
- Deploy via controlled SSH (read-only key)
- Store rollback artifact
- Verify health checks post-deployment

**Template available at**: `templates/github-workflow-deploy.yml`

#### 2.3 Deployment Artifact (可回滾 Artifact)

**Every production release MUST generate snapshot containing:**

```
deployment-artifacts/v1.2.3/
├── docker-compose.yml           # Exact compose config used
├── docker-images.digest         # Image digests for rollback
├── env-template.txt             # Env var keys (no secrets)
└── deployment-metadata.json     # Timestamp, deployer, commit
```

**Image digest example:**
```
# docker-images.digest
api-service@sha256:abc123...
worker-service@sha256:def456...
```

**Why this matters:**  
- With digest: Can rollback to EXACT same image (30 seconds)
- Without digest: "v1.2.2" tag might have been overwritten, impossible to rollback

**Env template example:**
```bash
# env-template.txt
# Production deployment v1.2.3
# Keys present (values not shown for security):

DATABASE_URL=***
API_KEY=***
SECRET_TOKEN=***
PROJECT_NAME=flemabus
ENVIRONMENT=production
```

#### 2.4 SSH Access Control (SSH 存取控制)

**Production servers MUST have two types of SSH keys:**

1. **Deploy Key (automation only):**
   ```bash
   # Restricted to deployment commands only
   # Can only: git pull, docker-compose up -d (using artifacts)
   # Cannot: docker-compose down, vim, rm
   ```

2. **Emergency Key (break-glass only):**
   ```bash
   # For emergency incidents ONLY
   # Requires: Engineering Lead approval + incident ticket
   # Logged: All commands are logged and reviewed
   ```

**How to restrict SSH commands** (in `~/.ssh/authorized_keys`):
```bash
# Deploy key (restricted)
command="bash /opt/scripts/deploy-only.sh",no-pty,no-port-forwarding ssh-rsa AAAA...

# Emergency key (logged)
command="bash /opt/scripts/audit-shell.sh",no-port-forwarding ssh-rsa AAAA...
```

**Deploy-only script** (`/opt/scripts/deploy-only.sh`):
```bash
#!/bin/bash
# Only allow specific deployment commands

case "$SSH_ORIGINAL_COMMAND" in
  "git pull")
    cd /opt/$PROJECT && git pull
    ;;
  "deploy-from-artifact "*")
    # Deploy using pre-built artifact
    bash /opt/scripts/deploy-from-artifact.sh "$2"
    ;;
  *)
    echo "❌ Command not allowed: $SSH_ORIGINAL_COMMAND"
    echo "Production deployments must go through GitHub Actions pipeline"
    exit 1
    ;;
esac
```

#### 2.5 Automated Checks (自動化檢查)

```bash
# Check 1: Production deployment workflow exists
test -f .github/workflows/deploy-production.yml || exit 1

# Check 2: Workflow only triggers on tags
grep -q "tags:" .github/workflows/deploy-production.yml || exit 1

# Check 3: Snapshot script present
test -f scripts/snapshot-release.sh || exit 1
```

**What blocks merge:**
- ❌ Missing deployment pipeline configuration
- ❌ Pipeline allows manual trigger
- ❌ No snapshot/artifact generation

---

### Gate #3: Least Privilege Access (最小權限存取) 🔴 **LIMITS BLAST RADIUS**

**Prevents**: Excessive permissions that amplify incident impact

**The Problem This Solves:**  
When incidents happen, excessive permissions turn small mistakes into catastrophic failures.  
當事故發生時，過度權限將小錯誤轉化為災難性失敗。

**Why This Gate Exists:**  
Not about trust. It's about **risk management** and **limiting blast radius**.  
不是關於信任。而是關於**風險管理**和**限制爆炸半徑**。

Even trusted engineers/vendors should operate under **least privilege principle**.

#### 3.1 Forbidden Permissions in Production (生產環境禁止的權限)

**The following permissions are FORBIDDEN for vendors/contractors:**

```bash
# ❌ FORBIDDEN: System administrator access
sudo access                    # Can destroy entire system
root access                    # Unrestricted system control
systemctl restart docker       # Can take down all services
shutdown / reboot             # System-level disruption

# ❌ FORBIDDEN: Database administrator access
Database superuser (postgres, root)  # Can drop all databases
GRANT / REVOKE permissions           # Can escalate privileges
CREATE / DROP database               # Data loss risk
ALTER system settings                # Performance impact

# ❌ FORBIDDEN: Direct deployment access
Direct SSH to production             # Bypasses audit trail (use pipeline only)
docker-compose down                  # Can take down services (already restricted by Gate #2)
Manual file editing in /opt/         # Untracked changes
Direct database schema changes       # Bypasses migration control

# ❌ FORBIDDEN: Secret/credential access
Access to .env files                 # Contains secrets
Kubernetes secrets access            # Contains API keys
Password manager admin               # Can access all credentials
SSL certificate private keys         # Security compromise
```

#### 3.2 Allowed Permissions (Read + Observe) (允許的權限)

**Vendors/contractors should have:**

```bash
# ✅ ALLOWED: Read-only system access
docker ps                           # View running containers
docker logs                         # View application logs
docker-compose ps                   # View service status
systemctl status                    # View service health (no restart)

# ✅ ALLOWED: Read-only database access
Database read-only user             # SELECT only, no writes
pg_stat_activity view              # Query performance monitoring
EXPLAIN queries                     # Query analysis
No access to user tables with PII   # Privacy protection

# ✅ ALLOWED: Application logs access
Application logs via centralized logging (e.g., CloudWatch, ELK)
Structured log queries              # Troubleshooting
Metrics dashboards (Grafana, etc.)  # Performance monitoring
Alert notifications                 # Incident awareness

# ✅ ALLOWED: Deployment monitoring
GitHub Actions workflow status      # CI/CD pipeline visibility
Deployment history (git tags)       # Release tracking
Health check endpoints              # Service availability
```

#### 3.3 Permission Tiers (權限層級)

**Define three tiers of production access:**

```
Tier 1: Engineering Team (Internal Staff)
權限層級 1：工程團隊（內部員工）
────────────────────────────────────
✅ Full deployment access (via pipeline)
✅ Database admin (via bastion host, audited)
✅ Emergency SSH (logged, requires approval)
✅ Secret management
✅ Infrastructure changes
Blast radius: HIGH (but trusted + accountable)

Tier 2: Vendors/Contractors (External)
權限層級 2：供應商/承包商（外部）
────────────────────────────────────
✅ Read-only database access
✅ Application logs (no system logs)
✅ Metrics dashboards
✅ Deployment status (view only)
❌ No sudo
❌ No database writes
❌ No deployment control
❌ No secret access
Blast radius: MINIMAL

Tier 3: Monitoring/Alerting (Automated)
權限層級 3：監控/告警（自動化）
────────────────────────────────────
✅ Read-only metrics
✅ Health checks
✅ Log aggregation
❌ No write access
❌ No control plane access
Blast radius: NONE
```

#### 3.4 Technical Implementation (技術實作)

**How to enforce least privilege:**

**For Database Access:**
```sql
-- Create read-only user for vendors
CREATE USER vendor_readonly WITH PASSWORD 'strong_random_password';

-- Grant read access to specific schemas only
GRANT CONNECT ON DATABASE production_db TO vendor_readonly;
GRANT USAGE ON SCHEMA public TO vendor_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO vendor_readonly;

-- Prevent future privilege escalation
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO vendor_readonly;

-- Revoke dangerous permissions explicitly
REVOKE CREATE ON SCHEMA public FROM vendor_readonly;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM vendor_readonly;

-- Verify permissions
\du vendor_readonly
```

**For SSH Access:**
```bash
# Vendors get restricted shell (read-only operations only)
# Create in /etc/ssh/sshd_config

Match User vendor_user
    ForceCommand /usr/local/bin/readonly-shell.sh
    PermitTTY no
    X11Forwarding no
    AllowTcpForwarding no
```

**Readonly shell** (`/usr/local/bin/readonly-shell.sh`):
```bash
#!/bin/bash
# Read-only operations for vendors

case "$SSH_ORIGINAL_COMMAND" in
  "docker ps"|"docker-compose ps")
    exec docker ps
    ;;
  "docker logs"*)
    # Allow log viewing only
    exec docker logs $2
    ;;
  "tail -f /var/log/app/"*)
    # Allow log tailing
    exec tail -f $3
    ;;
  *)
    echo "❌ Permission denied: Read-only access only"
    echo "Allowed commands:"
    echo "  - docker ps"
    echo "  - docker logs <container>"
    echo "  - tail -f /var/log/app/<logfile>"
    exit 1
    ;;
esac
```

**For Secrets Access:**
```bash
# Use separate secret management for vendors
# They get COPY of non-sensitive configs only

# Internal team: Full access via AWS Secrets Manager / Vault
aws secretsmanager get-secret-value --secret-id prod/db/password

# Vendors: Only documentation about WHICH secrets exist
cat << EOF
Required secrets (values managed by Jasslin internal team):
- DATABASE_URL
- API_KEY
- JWT_SECRET

Vendors do NOT have access to actual values.
EOF
```

#### 3.5 Risk Management Justification (風險管理理由)

**When communicating this to management/clients:**

> "This is not about trust. This is about **industry-standard risk management.**
>
> **Principle of Least Privilege:**
> - Every user should have ONLY the minimum permissions needed for their job
> - This is a security best practice, not a trust issue
>
> **Why this matters:**
> - **Limits blast radius**: If credentials are compromised, damage is contained
> - **Compliance requirement**: Many standards (SOC 2, ISO 27001) require this
> - **Audit trail**: Read-only access is easier to audit and less risky
> - **Shared responsibility**: Internal team handles sensitive operations, vendors handle development
>
> **What vendors still can do:**
> - View logs for troubleshooting
> - Monitor application performance
> - Verify deployment success
> - Debug application issues
>
> **What vendors cannot do (by design):**
> - Drop databases (data loss risk)
> - Take down all services (availability risk)
> - Access customer data directly (privacy risk)
> - Bypass deployment pipeline (audit risk)
>
> This is how enterprise companies operate. It's not personal; it's professional."

#### 3.6 Automated Checks (自動化檢查)

```bash
# Check 1: Verify no sudo access for vendors
getent group sudo | grep -q vendor_user && {
  echo "❌ Vendor user has sudo access"
  exit 1
}

# Check 2: Verify database user is read-only
psql -U vendor_readonly -c "CREATE TABLE test (id INT);" 2>&1 | grep -q "permission denied" || {
  echo "❌ Vendor database user has write access"
  exit 1
}

# Check 3: Verify SSH restrictions in place
grep -q "Match User vendor_user" /etc/ssh/sshd_config || {
  echo "⚠️  SSH restrictions not configured for vendor users"
}
```

**What blocks merge:**
- ❌ Documentation shows vendor has admin access
- ❌ Database migration grants superuser
- ❌ SSH config allows unrestricted vendor access

#### 3.7 Permission Review Checklist (權限審查清單)

**Before granting any production access:**

- [ ] User requires **read-only** access first (default)
- [ ] Specific use case documented (why is access needed?)
- [ ] Time-limited access (expires after 90 days)
- [ ] Manager approval obtained
- [ ] Access logged and auditable
- [ ] Revocation procedure documented

**For vendor access specifically:**

- [ ] No sudo/root access
- [ ] Database is read-only
- [ ] No secret/credential access
- [ ] SSH restricted or disabled
- [ ] All actions logged
- [ ] Contract includes data protection clause

---

### Gate #4: Environment Isolation (環境隔離)

**Prevents**: Network conflicts that break multiple systems

**Checks** (automated by validate-hardgates.sh):
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

### Gate #5: Git-Tracked Configuration (配置追蹤)

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

### Gate #6: Rollback Capability (回滾能力)

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

### Gate #7: Service Persistence (服務持久性)

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

### Gate #8: Documentation (文件記錄)

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
