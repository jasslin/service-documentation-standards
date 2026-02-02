# Least Privilege Access Setup
# 最小權限存取設定

**Purpose**: Limit blast radius by restricting vendor/contractor permissions  
**目的**：透過限制供應商/承包商權限來限制爆炸半徑

**Time Required**: 30 minutes per production environment  
**所需時間**：每個生產環境 30 分鐘

---

## Executive Summary (管理層摘要)

**This is not about trust. This is about risk management.**  
**這不是關於信任。這是關於風險管理。**

### The Risk (風險)

When external vendors have admin access to production:
- Small mistakes become catastrophic failures
- Compromised vendor credentials = full system access
- No limit to blast radius
- Difficult to audit who did what

### The Solution (解決方案)

**Least Privilege Principle**: Everyone gets ONLY the minimum permissions needed.

**Result**:
- ✅ Vendors can still troubleshoot and monitor
- ✅ Blast radius limited (can't drop databases)
- ✅ Better audit trail
- ✅ Industry-standard security practice

**This protects EVERYONE, including vendors** (they can't accidentally break things).

---

## Permission Tiers (權限層級)

### Tier 1: Internal Engineering Team

**Who**: Jasslin employees only

**Access**:
- ✅ Full deployment via pipeline
- ✅ Database admin (audited)
- ✅ Emergency SSH (logged)
- ✅ Secret management
- ✅ Infrastructure changes

**Accountability**: Employment contract, internal policies

---

### Tier 2: External Vendors/Contractors (READ-ONLY)

**Who**: External development teams, consultants

**Access** (read + observe only):
```bash
✅ docker ps                    # View containers
✅ docker logs <container>      # View logs
✅ docker-compose ps            # View services
✅ systemctl status <service>   # View status (no restart)
✅ tail -f /var/log/app/*       # View application logs
✅ Metrics dashboards          # Grafana, CloudWatch, etc.
✅ SELECT queries (read-only DB user)
```

**Forbidden**:
```bash
❌ sudo                        # System admin
❌ docker-compose down/up      # Service control
❌ Database superuser          # Data modification
❌ .env file access            # Secrets
❌ SSH unrestricted            # Root access
❌ systemctl restart           # Service control
❌ Direct production changes   # Must use pipeline
```

**Accountability**: Service contract, limited liability

---

### Tier 3: Monitoring/Automation

**What**: Automated systems, health checks, log aggregation

**Access**:
- ✅ Read-only metrics
- ✅ Health check endpoints
- ✅ Log collection (structured)

**Forbidden**:
- ❌ Any write operations
- ❌ Control plane access

---

## Technical Implementation (技術實作)

### Step 1: Database Access Control

#### Create Read-Only Database User

```sql
-- Connect as superuser
psql -U postgres production_db

-- Create read-only user for vendors
CREATE USER vendor_readonly WITH PASSWORD 'GenerateStrongRandomPassword123!';

-- Grant connection
GRANT CONNECT ON DATABASE production_db TO vendor_readonly;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO vendor_readonly;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO vendor_readonly;

-- Grant SELECT on all future tables (important!)
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO vendor_readonly;

-- Explicitly prevent writes
REVOKE INSERT, UPDATE, DELETE, TRUNCATE 
  ON ALL TABLES IN SCHEMA public 
  FROM vendor_readonly;

-- Prevent DDL operations
REVOKE CREATE ON SCHEMA public FROM vendor_readonly;

-- Prevent function execution (can be dangerous)
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM vendor_readonly;

-- Verify permissions
\du vendor_readonly

-- Test (should succeed)
SET ROLE vendor_readonly;
SELECT * FROM users LIMIT 1;

-- Test (should fail)
INSERT INTO users (name) VALUES ('test');
-- ERROR: permission denied for table users

-- Test (should fail)
DROP TABLE users;
-- ERROR: must be owner of table users
```

#### Protect Sensitive Tables

```sql
-- If some tables contain PII or sensitive data, revoke even SELECT
REVOKE SELECT ON TABLE payment_methods FROM vendor_readonly;
REVOKE SELECT ON TABLE customer_credit_cards FROM vendor_readonly;
REVOKE SELECT ON TABLE audit_logs FROM vendor_readonly;

-- Create views with sanitized data if needed
CREATE VIEW users_sanitized AS
SELECT 
  id,
  username,
  created_at,
  '***' AS email  -- Hide actual email
FROM users;

GRANT SELECT ON users_sanitized TO vendor_readonly;
```

---

### Step 2: SSH Access Control

#### Option A: Restricted Shell (Preferred)

Create `/usr/local/bin/vendor-readonly-shell.sh`:

```bash
#!/bin/bash
# Read-only shell for vendor access
# Only allows specific monitoring commands

set -e

LOG_FILE="/var/log/vendor-access.log"

# Log all commands
echo "$(date -u +"%Y-%m-%d %H:%M:%S UTC") | User: $USER | From: $SSH_CLIENT | Command: $SSH_ORIGINAL_COMMAND" >> "$LOG_FILE"

# Whitelist of allowed commands
case "$SSH_ORIGINAL_COMMAND" in
  # Container status
  "docker ps"|"docker-compose ps")
    exec docker ps
    ;;
  
  # View specific container logs
  "docker logs "*)
    CONTAINER=$(echo "$SSH_ORIGINAL_COMMAND" | awk '{print $3}')
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
      exec docker logs --tail=100 "$CONTAINER"
    else
      echo "❌ Container not found: $CONTAINER"
      exit 1
    fi
    ;;
  
  # Service status
  "systemctl status "*)
    SERVICE=$(echo "$SSH_ORIGINAL_COMMAND" | awk '{print $3}')
    exec systemctl status "$SERVICE"
    ;;
  
  # Application logs only (not system logs)
  "tail -f /var/log/app/"*)
    LOGFILE=$(echo "$SSH_ORIGINAL_COMMAND" | awk '{print $3}')
    if [[ "$LOGFILE" =~ ^/var/log/app/ ]]; then
      exec tail -f "$LOGFILE"
    else
      echo "❌ Access denied: Only /var/log/app/* allowed"
      exit 1
    fi
    ;;
  
  # Disk space (useful for troubleshooting)
  "df -h"|"du -sh /opt/"*)
    exec $SSH_ORIGINAL_COMMAND
    ;;
  
  # Network connectivity tests
  "ping -c 4 "*)
    exec $SSH_ORIGINAL_COMMAND
    ;;
  
  # Forbidden commands (explicit)
  "sudo "*|"docker-compose down"*|"docker-compose up"*|"systemctl restart"*|"rm "*|"mv "*|"cp "*|"vim "*|"nano "*|"cat /opt/"*|"cat /etc/"*)
    echo "=========================================="
    echo "❌ PERMISSION DENIED"
    echo "=========================================="
    echo ""
    echo "Command: $SSH_ORIGINAL_COMMAND"
    echo ""
    echo "This operation requires elevated privileges."
    echo "Vendors have read-only access for security and risk management."
    echo ""
    echo "This is industry-standard practice (Principle of Least Privilege)."
    echo ""
    echo "Allowed commands:"
    echo "  - docker ps"
    echo "  - docker logs <container>"
    echo "  - systemctl status <service>"
    echo "  - tail -f /var/log/app/<logfile>"
    echo "  - df -h"
    echo ""
    echo "For production changes, use the deployment pipeline."
    echo "For urgent issues, contact Jasslin Engineering Lead."
    echo "=========================================="
    exit 1
    ;;
  
  # Default: deny all other commands
  *)
    echo "❌ Command not allowed: $SSH_ORIGINAL_COMMAND"
    echo "Vendor access is read-only. Contact Engineering Lead for assistance."
    exit 1
    ;;
esac
```

Make executable:
```bash
sudo chmod +x /usr/local/bin/vendor-readonly-shell.sh
sudo chown root:root /usr/local/bin/vendor-readonly-shell.sh
```

#### Configure SSH for Vendor User

Edit `/etc/ssh/sshd_config`, add:

```bash
# Vendor access restrictions
Match User vendor_*
    ForceCommand /usr/local/bin/vendor-readonly-shell.sh
    PermitTTY no
    X11Forwarding no
    AllowTcpForwarding no
    AllowAgentForwarding no
```

Reload SSH:
```bash
sudo systemctl reload sshd
```

#### Create Vendor User

```bash
# Create user (no sudo group)
sudo useradd -m -s /bin/bash vendor_company_name
sudo passwd vendor_company_name  # Or use SSH key only

# Add to docker group (read-only via restricted shell)
sudo usermod -aG docker vendor_company_name

# Create .ssh directory for key
sudo mkdir -p /home/vendor_company_name/.ssh
sudo touch /home/vendor_company_name/.ssh/authorized_keys
sudo chmod 700 /home/vendor_company_name/.ssh
sudo chmod 600 /home/vendor_company_name/.ssh/authorized_keys
sudo chown -R vendor_company_name:vendor_company_name /home/vendor_company_name/.ssh

# Add vendor's public key
echo "ssh-ed25519 AAAA... vendor@company.com" | sudo tee /home/vendor_company_name/.ssh/authorized_keys
```

#### Option B: No SSH Access (Most Secure)

Instead of SSH, provide:
- Centralized logging (CloudWatch, ELK, Splunk)
- Metrics dashboards (Grafana, DataDog)
- Read-only database credentials
- CI/CD pipeline access (view only)

```bash
# Disable SSH entirely for vendor
# Give them dashboard URLs instead:

Logs: https://cloudwatch.aws.amazon.com/...
Metrics: https://grafana.company.com/d/vendor-dashboard
Deployments: https://github.com/company/repo/actions
Database: host=replica.db.company.com user=vendor_readonly
```

---

### Step 3: Secrets Management

#### Separate Vendor Environment Variables

Create `/opt/service/.env.vendor` (read-only copy without secrets):

```bash
# .env.vendor - Safe for vendor viewing
# Does NOT contain actual secrets

PROJECT_NAME=flemabus
ENVIRONMENT=production
LOG_LEVEL=info
API_VERSION=v1

# Required secrets (values managed by Jasslin team):
# - DATABASE_URL (vendor has separate read-only connection)
# - API_KEY (not accessible to vendors)
# - JWT_SECRET (not accessible to vendors)
# - STRIPE_SECRET_KEY (not accessible to vendors)
```

Set permissions:
```bash
sudo chown root:vendor_company_name /opt/service/.env.vendor
sudo chmod 640 /opt/service/.env.vendor
```

#### Actual Secrets (Internal Only)

```bash
# .env - Full secrets, internal team only
sudo chown root:deploy /opt/service/.env
sudo chmod 600 /opt/service/.env

# Vendors cannot read this file
sudo ls -la /opt/service/.env
# -rw------- 1 root deploy 1234 Feb 02 17:30 .env
```

---

### Step 4: Audit Logging

#### Enable Command Logging

```bash
# All vendor commands are logged
tail -f /var/log/vendor-access.log

# Example output:
# 2026-02-02 17:30:15 UTC | User: vendor_company_name | From: 203.0.113.45 | Command: docker ps
# 2026-02-02 17:31:22 UTC | User: vendor_company_name | From: 203.0.113.45 | Command: docker logs api-service
```

#### Regular Audit Reviews

```bash
# Count vendor access per day
grep "$(date +%Y-%m-%d)" /var/log/vendor-access.log | wc -l

# Most common commands
grep "Command:" /var/log/vendor-access.log | awk -F'Command: ' '{print $2}' | sort | uniq -c | sort -rn | head -10

# Any denied commands (security review)
grep "PERMISSION DENIED" /var/log/vendor-access.log
```

---

## Communication Templates (溝通範本)

### For Management: Risk Management Justification

```
Subject: Production Access Policy Update - Risk Management

Hi [Manager],

We're implementing industry-standard access controls for production environments.

Context:
- Current state: External vendors have admin-level access
- Risk: No limit to blast radius if credentials compromised or mistakes happen
- Solution: Principle of Least Privilege (read-only access for vendors)

This is NOT about trust. It's about:
✓ Risk management (SOC 2, ISO 27001 requirement)
✓ Limiting blast radius (contain damage if incidents occur)
✓ Clear accountability (audit trail)
✓ Protecting vendors too (can't accidentally break things)

What changes:
- Vendors get read-only access (logs, metrics, monitoring)
- Production changes go through pipeline (already implemented)
- Database access is SELECT-only (can't accidentally drop tables)

What stays the same:
- Vendors can troubleshoot issues
- Vendors can monitor performance
- Vendors can debug application code

This is how Fortune 500 companies operate. It's professional risk management.

Ready to proceed: [Date]
```

### For Vendors: Professional Communication

```
Subject: Production Access Update - Security Best Practices

Hi [Vendor Team],

As part of our ongoing security improvements, we're implementing the Principle of Least Privilege for all production environments.

What this means:
✓ You'll have read-only access to production (logs, metrics, monitoring)
✓ Database access will be SELECT-only (sufficient for troubleshooting)
✓ Production deployments continue via GitHub Actions pipeline
✓ All access is logged for security compliance

Why this change:
- Industry standard security practice (SOC 2, ISO 27001)
- Protects everyone by limiting blast radius
- Clear audit trail for compliance
- Reduces risk of accidental production changes

What you can still do:
✓ View application logs (docker logs, /var/log/app/*)
✓ Monitor metrics and dashboards
✓ Query database for troubleshooting (read-only)
✓ View deployment status
✓ Debug application issues

What changes:
✗ Direct docker-compose operations (use pipeline instead)
✗ Database writes (SELECT only)
✗ System administration (sudo access)

Implementation date: [Date]

New credentials:
- SSH: vendor_company@production-server (restricted shell)
- Database: vendor_readonly / [password]
- Dashboards: [URLs]

This protects both of us and is standard practice in enterprise environments.

Questions? Contact: engineering-lead@jasslin.com
```

---

## Verification & Testing (驗證與測試)

### Test Vendor Database Access

```bash
# As vendor user, should succeed:
psql -h production-db -U vendor_readonly -d production_db -c "SELECT COUNT(*) FROM users;"

# Should fail:
psql -h production-db -U vendor_readonly -d production_db -c "DELETE FROM users WHERE id=1;"
# ERROR: permission denied for table users

psql -h production-db -U vendor_readonly -d production_db -c "DROP TABLE users;"
# ERROR: must be owner of table users

psql -h production-db -U vendor_readonly -d production_db -c "CREATE TABLE test (id INT);"
# ERROR: permission denied for schema public
```

### Test Vendor SSH Access

```bash
# As vendor SSH user, should succeed:
ssh vendor_company@production "docker ps"
ssh vendor_company@production "docker logs api-service"
ssh vendor_company@production "systemctl status docker"

# Should fail:
ssh vendor_company@production "sudo systemctl restart docker"
# ❌ PERMISSION DENIED

ssh vendor_company@production "docker-compose down"
# ❌ PERMISSION DENIED

ssh vendor_company@production "cat /opt/service/.env"
# ❌ PERMISSION DENIED

ssh vendor_company@production "rm -rf /tmp/test"
# ❌ PERMISSION DENIED
```

### Test Secret Access

```bash
# Vendor user should NOT be able to read secrets
sudo -u vendor_company cat /opt/service/.env
# Permission denied

# Vendor can read vendor config
sudo -u vendor_company cat /opt/service/.env.vendor
# Success (but no secrets)
```

---

## Maintenance & Review (維護與審查)

### Quarterly Access Review

```bash
# List all users with production access
sudo awk -F: '$3 >= 1000 {print $1}' /etc/passwd

# Check sudo group members
getent group sudo

# Review vendor access logs
grep -c "vendor_" /var/log/vendor-access.log

# Any permission escalation attempts?
grep "PERMISSION DENIED" /var/log/vendor-access.log
```

### Annual Permission Audit

- [ ] Review all production user accounts
- [ ] Verify no vendors in sudo group
- [ ] Confirm database users are read-only
- [ ] Check SSH restrictions are enforced
- [ ] Review secret access (who has .env access)
- [ ] Update vendor credentials (password rotation)
- [ ] Document any exceptions with business justification

---

## Emergency Escalation (緊急升級)

### When Vendor Needs Elevated Access

**ONLY in critical production outage:**

1. **Open incident ticket** with details
2. **Engineering Lead approval** required
3. **Time-limited elevation** (e.g., 4 hours)
4. **Grant temporary access**:
   ```bash
   # Temporarily add to sudo group
   sudo usermod -aG sudo vendor_company
   
   # Set expiration
   sudo usermod --expiredate $(date -d "+4 hours" +%Y-%m-%d) vendor_company
   ```
5. **Monitor actions** (all commands logged)
6. **Revoke immediately** after incident resolution
7. **Post-incident review** (what was done, why elevated access was needed)
8. **Update procedures** (prevent future need for elevation)

---

## Summary Checklist (總結檢查清單)

**Before declaring "least privilege" is enforced:**

- [ ] Vendors have read-only database user
- [ ] Vendors cannot run `sudo` commands
- [ ] Vendors cannot run `docker-compose down/up`
- [ ] Vendors cannot access `.env` files
- [ ] Vendors can view logs (docker logs, /var/log/app/*)
- [ ] Vendors can view metrics dashboards
- [ ] SSH restricted shell configured
- [ ] All vendor actions logged
- [ ] Regular audit reviews scheduled
- [ ] Communication sent to vendors (professional tone)
- [ ] Management approval obtained
- [ ] Emergency escalation procedure documented

---

## Benefits (效益)

**Before Least Privilege:**
- ❌ Vendor mistake can drop entire database
- ❌ Compromised vendor credentials = full system access
- ❌ No limit to blast radius
- ❌ Difficult to audit

**After Least Privilege:**
- ✅ Vendor mistake contained (can't modify data)
- ✅ Compromised credentials = read-only access only
- ✅ Blast radius limited
- ✅ Clear audit trail
- ✅ Compliance with SOC 2, ISO 27001
- ✅ Professional risk management

**這不是不信任供應商。這是保護所有人（包括供應商）的專業風險管理。**

This is not distrust. This is professional risk management that protects everyone (including vendors).
