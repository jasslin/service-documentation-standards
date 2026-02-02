# SSH Access Restriction Setup
# SSH 存取限制設定

**Purpose**: Prevent manual docker-compose operations that caused 2-week outage  
**目的**：防止導致兩週停機的手動 docker-compose 操作

**Time Required**: 10 minutes per production server  
**所需時間**：每台生產伺服器 10 分鐘

---

## Why This Matters (為何重要)

### The Problem (問題)

In the incident, an engineer:
1. SSH'd to production server
2. Navigated to wrong directory
3. Ran `docker-compose down`
4. Brought down production for 2 weeks

**This happened because there were NO restrictions on SSH operations.**

### The Solution (解決方案)

**Two-tier SSH access:**
1. **Deploy Key** (automation only) - Restricted commands
2. **Emergency Key** (break-glass only) - Logged and audited

**Result**: Manual `docker-compose down` is technically impossible via deploy key.

---

## Setup Instructions (設定指南)

### Step 1: Create Deploy User

On production server:

```bash
# Create dedicated deployment user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy  # Add to docker group

# Create directory structure
sudo mkdir -p /opt/{scripts,deployments}
sudo chown deploy:deploy /opt/{scripts,deployments}
```

### Step 2: Generate SSH Keys

On your local machine or CI/CD server:

```bash
# Generate deploy key (for automation)
ssh-keygen -t ed25519 -C "deploy@production-flemabus" -f deploy_key
# Passphrase: leave empty for automation

# Generate emergency key (for humans)
ssh-keygen -t ed25519 -C "emergency@production-flemabus" -f emergency_key
# Passphrase: use strong passphrase

# Result:
# deploy_key      deploy_key.pub       (automation)
# emergency_key   emergency_key.pub    (humans)
```

### Step 3: Create Restricted Command Scripts

On production server, create `/opt/scripts/deploy-only.sh`:

```bash
#!/bin/bash
# Restricted deployment commands
# Only allows specific operations needed by CI/CD pipeline

set -e

LOG_FILE="/var/log/deploy-commands.log"

# Log all commands
echo "$(date -u +"%Y-%m-%d %H:%M:%S UTC") | User: $USER | Command: $SSH_ORIGINAL_COMMAND" >> "$LOG_FILE"

case "$SSH_ORIGINAL_COMMAND" in
  # Allow: Upload deployment artifact
  "scp -t /tmp/deployment-snapshot.tar.gz")
    exec /usr/bin/scp -t /tmp/deployment-snapshot.tar.gz
    ;;
  
  # Allow: Deploy from artifact
  deploy-from-artifact\ *)
    PROJECT=$(echo "$SSH_ORIGINAL_COMMAND" | awk '{print $2}')
    if [ ! -d "/opt/$PROJECT" ]; then
      echo "❌ Invalid project: $PROJECT"
      exit 1
    fi
    exec bash /opt/scripts/deploy-from-artifact.sh "$PROJECT"
    ;;
  
  # Allow: Health check
  "docker-compose ps"|"docker ps")
    cd /opt/* 2>/dev/null && exec docker-compose ps
    ;;
  
  # Allow: View logs
  "docker-compose logs"*)
    cd /opt/* 2>/dev/null && exec docker-compose logs
    ;;
  
  # FORBIDDEN: All other commands
  *)
    echo "=========================================="
    echo "❌ COMMAND NOT ALLOWED"
    echo "=========================================="
    echo ""
    echo "Command attempted: $SSH_ORIGINAL_COMMAND"
    echo ""
    echo "Production deployments MUST go through GitHub Actions pipeline."
    echo "Manual docker-compose operations are FORBIDDEN."
    echo ""
    echo "This restriction prevents:"
    echo "  - Accidental docker-compose down (caused 2-week outage)"
    echo "  - Operations in wrong directory"
    echo "  - Untracked configuration changes"
    echo ""
    echo "Allowed commands:"
    echo "  - scp (upload deployment artifacts)"
    echo "  - deploy-from-artifact <project>"
    echo "  - docker-compose ps (read-only)"
    echo "  - docker-compose logs (read-only)"
    echo ""
    echo "For emergency access, use emergency key with Engineering Lead approval."
    echo "=========================================="
    exit 1
    ;;
esac
```

Make executable:
```bash
sudo chmod +x /opt/scripts/deploy-only.sh
sudo chown root:root /opt/scripts/deploy-only.sh
```

### Step 4: Create Deployment Script

Create `/opt/scripts/deploy-from-artifact.sh`:

```bash
#!/bin/bash
# Deploy from pre-built artifact
# This is the ONLY way to deploy to production

set -e

PROJECT=$1
DEPLOY_PATH="/opt/$PROJECT"

if [ -z "$PROJECT" ]; then
  echo "❌ Project name required"
  exit 1
fi

if [ ! -d "$DEPLOY_PATH" ]; then
  echo "❌ Project directory not found: $DEPLOY_PATH"
  exit 1
fi

if [ ! -f "/tmp/deployment-snapshot.tar.gz" ]; then
  echo "❌ Deployment artifact not found: /tmp/deployment-snapshot.tar.gz"
  exit 1
fi

echo "=========================================="
echo "Production Deployment"
echo "Project: $PROJECT"
echo "Time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "User: $USER"
echo "=========================================="

# Extract artifact
cd "$DEPLOY_PATH"
mkdir -p /tmp/deployment-snapshot
tar -xzf /tmp/deployment-snapshot.tar.gz -C /tmp/deployment-snapshot

# Backup current state
if [ -f docker-compose.yml ]; then
  mkdir -p backups
  BACKUP_FILE="backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$BACKUP_FILE" docker-compose.yml .env 2>/dev/null || true
  echo "✅ Current state backed up: $BACKUP_FILE"
fi

# Deploy new configuration
cp /tmp/deployment-snapshot/deployment-snapshot/docker-compose.yml ./
echo "✅ Configuration updated"

# Pull images
docker-compose pull
echo "✅ Images pulled"

# Deploy
docker-compose up -d --remove-orphans
echo "✅ Containers restarted"

# Cleanup
rm -rf /tmp/deployment-snapshot /tmp/deployment-snapshot.tar.gz

# Verify
sleep 5
docker-compose ps

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETED"
echo "=========================================="
```

Make executable:
```bash
sudo chmod +x /opt/scripts/deploy-from-artifact.sh
sudo chown deploy:deploy /opt/scripts/deploy-from-artifact.sh
```

### Step 5: Configure authorized_keys

On production server, edit `/home/deploy/.ssh/authorized_keys`:

```bash
# Deploy Key (Restricted - Automation Only)
# Only allows specific deployment commands
# Cannot run docker-compose down or other destructive operations
command="bash /opt/scripts/deploy-only.sh",no-pty,no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAA[your-deploy-key-public-key-here] deploy@production-flemabus

# Emergency Key (Logged - Human Use Only)
# Requires Engineering Lead approval
# All commands are logged and audited
command="bash /opt/scripts/audit-shell.sh",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAA[your-emergency-key-public-key-here] emergency@production-flemabus
```

Set permissions:
```bash
chmod 600 /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
```

### Step 6: Create Audit Shell (for emergency key)

Create `/opt/scripts/audit-shell.sh`:

```bash
#!/bin/bash
# Audited shell for emergency access
# All commands are logged

LOG_FILE="/var/log/emergency-access.log"

# Log session start
{
  echo "========================================"
  echo "Emergency Access Session"
  echo "Time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo "User: $USER"
  echo "From: $SSH_CLIENT"
  echo "========================================"
} >> "$LOG_FILE"

# Display warning
cat << 'EOF'
========================================
⚠️  EMERGENCY ACCESS
========================================

This is the emergency access shell.
All commands are LOGGED and AUDITED.

Emergency access requires:
- Active incident ticket
- Engineering Lead approval
- Post-incident review

For routine deployments, use GitHub Actions pipeline.

Press Ctrl+D to exit when done.
========================================
EOF

# Start audited shell
exec /bin/bash -l 2>&1 | tee -a "$LOG_FILE"
```

Make executable:
```bash
sudo chmod +x /opt/scripts/audit-shell.sh
sudo chown root:root /opt/scripts/audit-shell.sh
```

### Step 7: Test Access

#### Test Deploy Key (should be restricted):

```bash
# On your local machine
ssh -i deploy_key deploy@production-server "docker-compose ps"
# ✅ Should work (read-only)

ssh -i deploy_key deploy@production-server "docker-compose down"
# ❌ Should FAIL with "COMMAND NOT ALLOWED"

ssh -i deploy_key deploy@production-server "ls -la"
# ❌ Should FAIL with "COMMAND NOT ALLOWED"
```

#### Test Emergency Key (should be logged):

```bash
ssh -i emergency_key deploy@production-server
# ✅ Should work, but show warning and log commands
```

---

## Usage in CI/CD Pipeline (CI/CD 管道中的使用)

### GitHub Actions Configuration

Add secrets to repository:
- `PRODUCTION_SSH_KEY` - Content of `deploy_key` (private key)
- `PRODUCTION_HOST` - Production server hostname/IP

The deploy workflow (`templates/github-workflow-deploy.yml`) will:
1. Use deploy key to upload artifact
2. Execute `deploy-from-artifact` command
3. Deploy key CANNOT run any other commands

---

## Verification Checklist (驗證檢查清單)

After setup, verify:

- [ ] Deploy user created with docker group membership
- [ ] Deploy key restricts to deployment commands only
- [ ] Emergency key logs all commands
- [ ] `docker-compose down` is BLOCKED via deploy key
- [ ] Manual file edits are BLOCKED via deploy key
- [ ] Deploy-from-artifact script works correctly
- [ ] Backups are created before each deployment
- [ ] Logs are written to `/var/log/deploy-commands.log`
- [ ] Emergency access logs to `/var/log/emergency-access.log`

---

## Emergency Access Procedure (緊急存取程序)

### When to Use Emergency Key:

**ONLY in critical production outage where:**
- Automated pipeline is not working
- Immediate manual intervention required
- Engineering Lead has approved

### Process:

1. **Open incident ticket** with details
2. **Get Engineering Lead approval** (email/Slack confirmation)
3. **Use emergency key**:
   ```bash
   ssh -i emergency_key deploy@production-server
   ```
4. **Perform minimum necessary operations**
5. **Exit immediately** (Ctrl+D)
6. **Post-incident review**:
   - Review `/var/log/emergency-access.log`
   - Document what was done
   - Update runbooks
   - Fix automation to prevent future need

---

## Maintenance (維護)

### Rotate Keys Annually:

```bash
# Generate new keys
ssh-keygen -t ed25519 -C "deploy@production-v2" -f deploy_key_v2

# Update authorized_keys on server
# Update GitHub repository secrets
# Test new key
# Revoke old key
```

### Monitor Logs:

```bash
# Review deployment commands
sudo tail -f /var/log/deploy-commands.log

# Review emergency access (should be rare)
sudo tail -f /var/log/emergency-access.log

# If emergency access is frequent, something is wrong with automation
```

### Audit Trail:

```bash
# Count emergency accesses (should be near zero)
sudo grep "Emergency Access Session" /var/log/emergency-access.log | wc -l

# Review what commands were run during emergency access
sudo grep -A 20 "Emergency Access Session" /var/log/emergency-access.log
```

---

## Security Notes (安全注意事項)

### Deploy Key Security:

- ✅ Store in GitHub Secrets (encrypted)
- ✅ Never commit to git
- ✅ Restrict to specific commands only
- ✅ No passphrase (for automation)
- ✅ Rotate annually

### Emergency Key Security:

- ✅ Strong passphrase required
- ✅ Store in password manager
- ✅ Shared only with Engineering Lead
- ✅ All usage logged and audited
- ✅ Rotate after each use (recommended)

### Server Security:

- Disable password authentication (`PasswordAuthentication no`)
- Enable only key-based auth
- Restrict SSH to specific IPs (optional)
- Monitor failed login attempts
- Enable automatic security updates

---

## Summary (總結)

**Before this setup:**
- ❌ Engineers can SSH and run any command
- ❌ `docker-compose down` in wrong directory possible
- ❌ No audit trail
- ❌ Caused 2-week outage

**After this setup:**
- ✅ Deploy key restricted to specific commands
- ✅ `docker-compose down` technically impossible via automation
- ✅ All emergency access logged
- ✅ Deployments only via pipeline

**Result**: Manual operations that caused 2-week outage are now technically prevented.

這項技術控制使導致兩週停機的手動操作在技術上無法執行。
