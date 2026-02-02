# Production Service Documentation Standards
# 生產服務文檔標準

**Repository Purpose**: Central governance for Jasslin managed services  
**儲存庫目的**：Jasslin 託管服務的中央治理

**Version**: 2.0.0  
**Last Updated**: 2026-02-02

---

## Quick Navigation (快速導航)

| Document | Purpose | Audience |
|----------|---------|----------|
| **[RELEASE_POLICY.md](RELEASE_POLICY.md)** | Production release requirements, mandatory gates | Engineers deploying to production |
| **[OPS_RUNBOOK.md](OPS_RUNBOOK.md)** | Index of all service documentation locations | On-call engineers, operations |
| **[templates/docs/](templates/docs/)** | Documentation templates (ARCHITECTURE, DEPLOY, etc.) | Engineers creating new services |

---

## The Incident (事故起源)

### What Happened (發生了什麼)

**Date**: January 2026  
**Service**: Flemabus (mission-critical client system)  
**Total Downtime**: **TWO WEEKS**

A routine server reboot triggered complete service failure. Multiple engineers attempted recovery but failed. The system was eventually restored only after consulting a specific engineer who held critical knowledge in memory.

### Root Causes (根本原因)

The investigation revealed **five critical failures**:

1. **Network Naming Conflicts**  
   New deployment used generic network names (app-network), conflicting with production, breaking BOTH systems.

2. **Accidental `docker-compose down`**  
   Engineer ran command in wrong directory, bringing down production for 2 weeks.

3. **No Rollback Capability**  
   No git tags, no backup configuration, no way to restore previous working state.

4. **Service Persistence Not Configured**  
   Docker daemon not auto-enabled, no `restart: always` policies.

5. **Knowledge Single-Point-of-Failure**  
   Critical system knowledge existed only in one person's memory. Multiple engineers couldn't recover the system.

### Business Impact (業務影響)

- **2 weeks** of zero service availability
- Complete client business interruption
- Major SLA violation penalties
- Contract termination risk
- Severe reputational damage
- Potential legal liability

### The Lesson (教訓)

**This incident was 100% preventable.**

It was NOT caused by complex technical challenges or unforeseen edge cases.

It WAS caused by:
- Lack of environment isolation (network conflicts)
- Manual operations without safeguards (wrong-directory accidents)
- No versioning or rollback plan
- Missing service persistence configuration
- No documentation (knowledge concentration)

---

## The Solution: Technical Controls (解決方案：技術控制)

This repository defines **enforceable technical requirements** that prevent these failures.

### 🔴 Hard Gates (Mandatory, Blocks Release)

Eight automated checks that **MUST pass** before any production deployment:

1. **Merge Control** 🔴 — Branch protection + CODEOWNERS + CI (enforcement mechanism)
2. **Automated Release** 🔴 — Pipeline-only deployment, no manual SSH (prevents accidental docker-compose down)
3. **Least Privilege** 🔴 — Read-only vendor access (limits blast radius, risk management not trust)
4. **Environment Isolation** — Project-specific naming (prevents network conflicts)
5. **Git-Tracked Configuration** — No manual operations (prevents wrong-directory accidents)
6. **Rollback Capability** — Git tags + deployment snapshots (30-second rollback vs 2-week recovery)
7. **Service Persistence** — restart: always + healthcheck (survives reboots)
8. **Documentation** — 4 required files (eliminates knowledge single-point-of-failure)

**Gates #1-3 are enforcement mechanisms. Gates #4-8 are validated requirements.**  
**No need to ask for transparency — technical controls enforce it automatically.**

**Details**: See [RELEASE_POLICY.md](RELEASE_POLICY.md)  
**Setup Guide**: See [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md)

### 🟡 Aspirational Standards (Recommended)

Best practices that improve quality but don't block deployment:
- Unit test coverage >80%
- Bilingual documentation (English + Chinese)
- Hard reboot test on staging
- Performance benchmarks
- QA sign-off

---

## For Engineers Deploying to Production

### Before Every Release:

```bash
# 1. Run validation
bash scripts/validate-hardgates.sh

# 2. If all pass → Submit PR
# 3. After approval → Tag and deploy
git tag -a v1.2.3 -m "Production release"
git push origin v1.2.3

# 4. On production server
cd /opt/[service-name]
git fetch --tags
git checkout v1.2.3
docker-compose up -d
```

**Full procedures**: [RELEASE_POLICY.md](RELEASE_POLICY.md)

---

## For On-Call Engineers

### When Service is Down:

1. **Find service documentation**  
   → See [OPS_RUNBOOK.md](OPS_RUNBOOK.md) for locations

2. **Read RESILIENCE.md** (in service's repository)  
   → Recovery procedures and rollback steps

3. **Attempt rollback** (if recent deployment):
   ```bash
   cd /opt/[service-name]
   git checkout v[previous-version]
   docker-compose up -d
   ```

4. **If recovery fails**  
   → Contact service owner (listed in OPS_RUNBOOK.md)

**Full index**: [OPS_RUNBOOK.md](OPS_RUNBOOK.md)

---

## For Engineers Creating New Services

### Required Documentation (4 files):

| Template | Purpose |
|----------|---------|
| **ARCHITECTURE.md** | System design, Mermaid diagram, dependencies |
| **DEPLOY.md** | Deployment steps, environment variables |
| **RESILIENCE.md** | Self-healing config, recovery procedures |
| **TEST_REPORT.md** | Staging verification, hard reboot test |

**Templates available**: [templates/docs/](templates/docs/)

### Setup:

```bash
# 1. Copy templates to your service repo
cp -r /path/to/documentation-management/templates/docs/ ./docs/

# 2. Fill in all 4 documents

# 3. Ensure docker-compose.yml meets requirements:
services:
  api:
    container_name: projectname-api  # Project-specific name
    restart: always                   # Required
    networks:
      - projectname-network           # Custom network
    healthcheck:                      # Required
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s

networks:
  projectname-network:
    driver: bridge

# 4. Validate
bash /path/to/documentation-management/scripts/validate-hardgates.sh

# 5. Tag first production release
git tag -a v1.0.0 -m "Initial production release"
```

---

## Repository Structure (儲存庫結構)

```
documentation-management/
├── README.md                         ← You are here
├── RELEASE_POLICY.md                ← Production release requirements (all 8 gates)
├── OPS_RUNBOOK.md                   ← Index to all service documentation
├── SETUP_BRANCH_PROTECTION.md       ← Gate #1: GitHub branch protection
├── SETUP_SSH_RESTRICTION.md         ← Gate #2: SSH access restriction
├── SETUP_LEAST_PRIVILEGE.md         ← Gate #3: Least privilege access
├── scripts/
│   ├── validate-hardgates.sh        ← Automated validation (used by CI)
│   └── snapshot-release.sh          ← Release snapshot generator
└── templates/
    ├── CODEOWNERS                    ← Code review enforcement
    ├── github-workflow-validate.yml  ← CI validation workflow
    ├── github-workflow-deploy.yml    ← Production deployment pipeline
    └── docs/                          ← Documentation templates
        ├── ARCHITECTURE.md
        ├── DEPLOY.md
        ├── RESILIENCE.md
        └── TEST_REPORT.md
```

---

## Policy Enforcement (政策執行)

### How Requirements are Enforced:

1. **Automated validation** — `validate-hardgates.sh` runs on every PR
2. **CI/CD integration** — Cannot merge if validation fails
3. **Git tag requirement** — Production servers only accept tagged versions
4. **PR approval required** — No direct commits to main branch

**These are technical controls, not trust-based policies.**  
**這些是技術控制，而非基於信任的政策。**

### What Happens When Gates Fail:

- CI/CD pipeline fails (red X on PR)
- Cannot merge until fixed
- Deployment blocked

**No exceptions. No overrides** (except critical production outage with Engineering Lead approval).

---

## Scope & Authority (範圍與權限)

### What This Repository Governs:

- ✅ Technical requirements for production deployment
- ✅ Documentation standards
- ✅ Automated validation criteria
- ✅ Rollback procedures

### What This Repository Does NOT Govern:

- ❌ Code quality standards (that's in individual repos)
- ❌ Business logic requirements
- ❌ HR/contractual enforcement
- ❌ QA approval processes (aspirational, not blocking)

### Authority:

**Authorized By**: Ezra Wu (吳豐吉), Engineer  
**Scope**: Technical deployment requirements enforceable by engineers  
**Enforcement**: Automated CI/CD checks

---

## Version History (版本歷史)

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 2.0.0 | 2026-02-02 | Restructure: separate RELEASE_POLICY and OPS_RUNBOOK | Ezra Wu |
| 1.0.0 | 2026-02-01 | Initial framework based on Flemabus incident | Ezra Wu |

---

## Questions & Contact (問題與聯絡)

### For Deployment Questions:
→ Read [RELEASE_POLICY.md](RELEASE_POLICY.md)

### For Operational Issues:
→ Read [OPS_RUNBOOK.md](OPS_RUNBOOK.md)

### For Policy Changes:
→ Submit PR to this repository  
→ Contact: Engineering Lead

---

**"Documentation is not bureaucracy. It is the foundation of reliability."**  
**「文件記錄不是官僚主義。它是可靠性的基礎。」**
