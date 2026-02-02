# Production Service Documentation Standards
# 生產服務文檔標準

**Repository Purpose** / **儲存庫目的**  
Central governance framework for Jasslin managed services, preventing production incidents through technical controls.  
Jasslin 託管服務的中央治理框架，透過技術控制防止生產事故。

**Version** / **版本**: 3.0.0  
**Last Updated** / **最後更新**: 2026-02-02  
**Git Workflow** / **Git 工作流**: GitHub Flow (single `main` branch)

---

## 📚 Document Map / 文檔地圖

### Core Documents / 核心文檔

| Document | Purpose (EN) | 用途 (中) | Read When |
|----------|-------------|----------|-----------|
| **[RELEASE_POLICY.md](RELEASE_POLICY.md)** | Complete policy with all 11 hard gates | 完整政策與 11 個硬性閘門 | Before any production deployment |
| **[OPS_RUNBOOK.md](OPS_RUNBOOK.md)** | Service documentation index | 服務文檔索引 | When troubleshooting incidents |

### Setup Guides / 設定指南

| Guide | Gate | Purpose (EN) | 用途 (中) | Setup Time |
|-------|------|-------------|----------|------------|
| **[SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md)** | Gate #1 | GitHub branch protection & CODEOWNERS | GitHub 分支保護與程式碼審查 | 5 min/repo |
| **[SETUP_SSH_RESTRICTION.md](SETUP_SSH_RESTRICTION.md)** | Gate #2 | Restrict SSH access, prevent manual operations | 限制 SSH 存取，防止手動操作 | 10 min/server |
| **[SETUP_LEAST_PRIVILEGE.md](SETUP_LEAST_PRIVILEGE.md)** | Gate #3 | Vendor read-only access setup | 供應商唯讀存取設定 | 30 min/env |

### Automation Scripts / 自動化腳本

| Script | Purpose (EN) | 用途 (中) | Used By |
|--------|-------------|----------|---------|
| **[scripts/validate-hardgates.sh](scripts/validate-hardgates.sh)** | Validate all 11 gates before merge | 合併前驗證所有 11 個閘門 | CI/CD pipeline |
| **[scripts/snapshot-release.sh](scripts/snapshot-release.sh)** | Generate deployment snapshot for rollback | 生成部署快照以供回滾 | Deployment pipeline |

### Templates / 模板

| Template | Purpose (EN) | 用途 (中) | Copy To |
|----------|-------------|----------|---------|
| **[templates/CODEOWNERS](templates/CODEOWNERS)** | Enforce code review for critical files | 強制審查關鍵檔案 | `.github/CODEOWNERS` |
| **[templates/github-workflow-validate.yml](templates/github-workflow-validate.yml)** | CI validation workflow | CI 驗證工作流程 | `.github/workflows/` |
| **[templates/github-workflow-deploy.yml](templates/github-workflow-deploy.yml)** | Production deployment pipeline | 生產部署管道 | `.github/workflows/` |
| **[templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md)** | System facts documentation template | 系統事實文檔模板 | `docs/SYSTEM_FACTS.md` |
| **[templates/docs/ARCHITECTURE.md](templates/docs/ARCHITECTURE.md)** | System architecture documentation | 系統架構文檔 | `docs/ARCHITECTURE.md` |
| **[templates/docs/DEPLOY.md](templates/docs/DEPLOY.md)** | Deployment procedures | 部署程序 | `docs/DEPLOY.md` |
| **[templates/docs/RESILIENCE.md](templates/docs/RESILIENCE.md)** | Self-healing & recovery procedures | 自我修復與恢復程序 | `docs/RESILIENCE.md` |
| **[templates/docs/TEST_REPORT.md](templates/docs/TEST_REPORT.md)** | Staging verification results | 預發環境驗證結果 | `docs/TEST_REPORT.md` |

---

## 🎯 Quick Start by Role / 按角色快速開始

### 👨‍💻 For Engineers Deploying to Production / 工程師部署到生產環境

**Workflow** / **工作流程** ([GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)):

```bash
# 1. Create feature branch from main / 從 main 建立功能分支
git checkout main && git pull
git checkout -b feature/your-change

# 2. Make changes and validate locally / 修改並本地驗證
bash scripts/validate-hardgates.sh

# 3. Push and create PR to main / 推送並建立 PR 到 main
git push origin feature/your-change
# Create PR via GitHub UI / 透過 GitHub UI 建立 PR

# 4. After PR approved and merged / PR 批准並合併後
git checkout main && git pull

# 5. Tag the merge commit / 標記合併提交
git tag -a v1.2.3 -m "Production release"
git push origin v1.2.3

# 6. GitHub Actions automatically deploys / GitHub Actions 自動部署
# (No manual operations / 無需手動操作)
```

**Related Documents** / **相關文檔**:
- 📖 [RELEASE_POLICY.md](RELEASE_POLICY.md) - Full deployment policy / 完整部署政策
- 🔧 [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md) - Setup guide / 設定指南

---

### 🚨 For On-Call Engineers / 值班工程師

**When Service is Down** / **服務停止時**:

```bash
# 1. Find service documentation / 查找服務文檔
# → See OPS_RUNBOOK.md for all service locations
# → 查看 OPS_RUNBOOK.md 以獲取所有服務位置

# 2. Check service-specific RESILIENCE.md for recovery steps
# → 查看服務特定的 RESILIENCE.md 以獲取恢復步驟

# 3. Attempt rollback (if recent deployment) / 嘗試回滾（如果是最近部署）
cd /opt/[service-name]
git checkout v[previous-version]
docker-compose up -d

# 4. If rollback fails, contact service owner
# → Listed in OPS_RUNBOOK.md
# → 在 OPS_RUNBOOK.md 中列出
```

**Related Documents** / **相關文檔**:
- 📗 [OPS_RUNBOOK.md](OPS_RUNBOOK.md) - Service documentation index / 服務文檔索引
- 🔄 [RELEASE_POLICY.md - Gate #9](RELEASE_POLICY.md#gate-9-rollback--no-panic-actions-回滾與禁止恐慌操作--prevents-panic-driven-destruction) - Rollback procedures / 回滾程序

---

### 🏗️ For Engineers Creating New Services / 工程師建立新服務

**Setup Checklist** / **設定檢查清單**:

```bash
# 1. Copy documentation templates / 複製文檔模板
cp -r documentation-management/templates/docs/ ./docs/
cp documentation-management/templates/SYSTEM_FACTS_CHECKLIST.md ./docs/SYSTEM_FACTS.md

# 2. Copy CI/CD workflows / 複製 CI/CD 工作流程
mkdir -p .github/workflows
cp documentation-management/templates/github-workflow-*.yml .github/workflows/
cp documentation-management/templates/CODEOWNERS .github/

# 3. Configure docker-compose.yml / 配置 docker-compose.yml
# Requirements / 要求:
# - Project name: name: projectname-prod
# - Network naming: projectname-prod-network (no generic names)
# - Container names: projectname-prod-service
# - restart: always (all services)
# - healthcheck: (all critical services)

# 4. Fill required documentation / 填寫必需文檔
# - docs/ARCHITECTURE.md
# - docs/DEPLOY.md
# - docs/RESILIENCE.md
# - docs/TEST_REPORT.md
# - docs/SYSTEM_FACTS.md (complete checklist)

# 5. Validate / 驗證
bash documentation-management/scripts/validate-hardgates.sh

# 6. Setup branch protection on GitHub / 在 GitHub 上設定分支保護
# → Follow SETUP_BRANCH_PROTECTION.md
```

**Related Documents** / **相關文檔**:
- 📄 [templates/docs/](templates/docs/) - Documentation templates / 文檔模板
- 📋 [templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md) - System facts template / 系統事實模板
- ⚙️ [templates/github-workflow-validate.yml](templates/github-workflow-validate.yml) - CI setup / CI 設定

---

### 👔 For Management / 管理層

**Key Points** / **關鍵要點**:

- ✅ **Risk Management, Not Trust** / **風險管理，而非信任**  
  All controls are technical (automated), not trust-based.  
  所有控制都是技術性的（自動化），而非基於信任。

- ✅ **Prevents 2-Week Outage Recurrence** / **防止兩週停機再次發生**  
  11 hard gates directly address root causes from the incident.  
  11 個硬性閘門直接針對事故的根本原因。

- ✅ **Industry Standard Practices** / **業界標準實踐**  
  Principle of Least Privilege, SOC 2, ISO 27001 compliance.  
  最小權限原則，符合 SOC 2、ISO 27001。

- ✅ **Vendor Can Still Work** / **供應商仍可工作**  
  Read-only access sufficient for troubleshooting and monitoring.  
  唯讀存取足以進行故障排除和監控。

**Related Documents** / **相關文檔**:
- 🎓 [SETUP_LEAST_PRIVILEGE.md - Executive Summary](SETUP_LEAST_PRIVILEGE.md#executive-summary-管理層摘要) - Risk management justification / 風險管理理由

---

## 🔒 The 11 Hard Gates / 11 個硬性閘門

**Summary Table** / **摘要表格**:

| Gate # | Name (EN) | 名稱 (中) | Type | Enforced By | Setup Guide |
|--------|-----------|----------|------|-------------|-------------|
| **#1** | Merge Control | 合併控制 | 🔴 Enforcement | GitHub | [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md) |
| **#2** | Automated Release | 自動化釋出 | 🔴 Enforcement | GitHub Actions | [SETUP_SSH_RESTRICTION.md](SETUP_SSH_RESTRICTION.md) |
| **#3** | Least Privilege | 最小權限 | 🔴 Enforcement | Server Config | [SETUP_LEAST_PRIVILEGE.md](SETUP_LEAST_PRIVILEGE.md) |
| **#4** | Environment Isolation (CI) | 環境隔離 (CI) | ⚙️ Validation | CI Check | [RELEASE_POLICY.md#gate-4](RELEASE_POLICY.md) |
| **#5** | Git-Tracked Config | Git 追蹤配置 | ⚙️ Validation | CI Check | [RELEASE_POLICY.md#gate-5](RELEASE_POLICY.md) |
| **#6** | Rollback Capability | 回滾能力 | ⚙️ Validation | CI Check | [RELEASE_POLICY.md#gate-6](RELEASE_POLICY.md) |
| **#7** | Service Persistence | 服務持久性 | ⚙️ Validation | CI Check | [RELEASE_POLICY.md#gate-7](RELEASE_POLICY.md) |
| **#8** | Environment Isolation (Ops) | 環境隔離 (運維) | 🔴 Standard | Manual Verify | [RELEASE_POLICY.md#gate-8](RELEASE_POLICY.md) |
| **#9** | No Panic Actions | 禁止恐慌操作 | 🔴 Standard | Manual Verify | [RELEASE_POLICY.md#gate-9](RELEASE_POLICY.md) |
| **#10** | System Facts | 系統事實 | 🔴 Standard | CI Check + Manual | [templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md) |
| **#11** | Documentation | 文檔記錄 | ⚙️ Validation | CI Check | [templates/docs/](templates/docs/) |

### Gate Categories / 閘門分類

**🔴 Enforcement Mechanisms** (prevent incidents / 防止事故):
- Gates #1-3: Technical controls that **cannot be bypassed** / 無法繞過的技術控制
- Example: GitHub blocks merge without approval / GitHub 在沒有批准的情況下阻止合併

**🔴 Operational Standards** (prevent same failures / 防止重複失敗):
- Gates #8-10: Prevent specific incident scenarios / 防止特定事故場景
- Example: Network naming prevents conflicts / 網路命名防止衝突

**⚙️ Technical Validations** (automated checks / 自動化檢查):
- Gates #4-7, #11: CI validates requirements / CI 驗證要求
- Example: CI checks for `restart: always` / CI 檢查 `restart: always`

---

## 📖 The Incident Story / 事故故事

### What Happened / 發生了什麼

**Date** / **日期**: January 2026 / 2026年1月  
**Service** / **服務**: Flemabus (mission-critical client / 關鍵客戶)  
**Total Downtime** / **總停機時間**: **TWO WEEKS** / **兩週**

A routine server reboot triggered complete service failure. Multiple engineers attempted recovery but failed. The system was eventually restored only after consulting a specific engineer who held critical knowledge in memory.

例行性伺服器重啟觸發了完全服務故障。多名工程師嘗試恢復但失敗。系統最終僅在諮詢一位擁有關鍵記憶知識的特定工程師後才得以恢復。

### Five Root Causes / 五個根本原因

| # | Root Cause (EN) | 根本原因 (中) | Prevented By Gate |
|---|----------------|--------------|-------------------|
| 1 | Network naming conflicts | 網路命名衝突 | Gate #8: Environment Isolation |
| 2 | Accidental `docker-compose down` | 意外執行 docker-compose down | Gate #2: Automated Release + Gate #9 |
| 3 | No rollback capability | 無回滾能力 | Gate #6: Rollback Capability |
| 4 | Service persistence not configured | 服務持久性未配置 | Gate #7: Service Persistence |
| 5 | Knowledge single-point-of-failure | 知識單點故障 | Gate #10: System Facts + Gate #11 |

### Business Impact / 業務影響

- 2 weeks of zero service availability / 2 週零服務可用性
- Complete client business interruption / 完全客戶業務中斷
- Major SLA violation penalties / 重大 SLA 違約罰款
- Contract termination risk / 合約終止風險
- Severe reputational damage / 嚴重聲譽損害

### The Lesson / 教訓

**This incident was 100% preventable.** / **此事故是 100% 可預防的。**

It was NOT caused by complex technical challenges.  
它不是由複雜的技術挑戰引起的。

It WAS caused by lack of basic technical controls.  
它是由缺乏基本技術控制引起的。

**→ This repository implements those controls.** / **→ 本儲存庫實施這些控制。**

---

## 🚀 Implementation Roadmap / 實施路線圖

### Phase 1: Core Enforcement (Week 1) / 第一階段：核心執行（第 1 週）

**Priority**: High / 高  
**Blocks deployment if missing**: Yes / 是

- [ ] Setup GitHub branch protection (Gate #1) / 設定 GitHub 分支保護
  - Follow: [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md)
  - Time: 5 min per repository / 每個儲存庫 5 分鐘
  
- [ ] Configure CI/CD validation (Gate #1) / 配置 CI/CD 驗證
  - Copy: [templates/github-workflow-validate.yml](templates/github-workflow-validate.yml)
  - Time: 10 min per repository / 每個儲存庫 10 分鐘

- [ ] Implement deployment pipeline (Gate #2) / 實施部署管道
  - Copy: [templates/github-workflow-deploy.yml](templates/github-workflow-deploy.yml)
  - Time: 30 min per service / 每個服務 30 分鐘

### Phase 2: Access Control (Week 2) / 第二階段：存取控制（第 2 週）

**Priority**: High / 高  
**Blocks deployment if missing**: No (can deploy with manual oversight) / 否（可在人工監督下部署）

- [ ] Setup SSH restrictions (Gate #2) / 設定 SSH 限制
  - Follow: [SETUP_SSH_RESTRICTION.md](SETUP_SSH_RESTRICTION.md)
  - Time: 10 min per server / 每台伺服器 10 分鐘

- [ ] Configure least privilege access (Gate #3) / 配置最小權限存取
  - Follow: [SETUP_LEAST_PRIVILEGE.md](SETUP_LEAST_PRIVILEGE.md)
  - Time: 30 min per environment / 每個環境 30 分鐘

### Phase 3: Documentation & Standards (Ongoing) / 第三階段：文檔與標準（持續）

**Priority**: Medium / 中  
**Blocks deployment if missing**: Yes (for new services) / 是（新服務）

- [ ] Create service documentation (Gates #8-11) / 建立服務文檔
  - Templates: [templates/docs/](templates/docs/)
  - Complete: [templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md)
  - Time: 2-4 hours per service / 每個服務 2-4 小時

- [ ] Validate existing services / 驗證現有服務
  - Run: `bash scripts/validate-hardgates.sh`
  - Fix any violations / 修正任何違規

---

## 📊 Repository Structure / 儲存庫結構

```
documentation-management/
│
├── 📄 README.md                         ← You are here / 你在這裡
│   └── Complete navigation and quick start guide
│       完整導航和快速入門指南
│
├── 📋 Core Policy Documents / 核心政策文檔
│   ├── RELEASE_POLICY.md               ← All 11 gates detailed / 所有 11 個閘門詳細說明
│   │   ├── Gate #1-3: Enforcement mechanisms / 執行機制
│   │   ├── Gate #4-7, #11: Technical validations / 技術驗證
│   │   └── Gate #8-10: Operational standards / 運維標準
│   │
│   └── OPS_RUNBOOK.md                  ← Service documentation index / 服務文檔索引
│       └── Links to all service docs / 連結到所有服務文檔
│
├── 🔧 Setup Guides / 設定指南
│   ├── SETUP_BRANCH_PROTECTION.md      ← Gate #1 implementation / 閘門 #1 實施
│   ├── SETUP_SSH_RESTRICTION.md        ← Gate #2 implementation / 閘門 #2 實施
│   └── SETUP_LEAST_PRIVILEGE.md        ← Gate #3 implementation / 閘門 #3 實施
│
├── 🤖 Automation Scripts / 自動化腳本
│   └── scripts/
│       ├── validate-hardgates.sh       ← CI validation / CI 驗證
│       └── snapshot-release.sh         ← Deployment snapshots / 部署快照
│
└── 📝 Templates / 模板
    └── templates/
        ├── CODEOWNERS                  ← Code review setup / 程式碼審查設定
        ├── github-workflow-validate.yml ← CI pipeline / CI 管道
        ├── github-workflow-deploy.yml   ← Deployment pipeline / 部署管道
        ├── SYSTEM_FACTS_CHECKLIST.md   ← Gate #10 template / 閘門 #10 模板
        └── docs/                        ← Service doc templates / 服務文檔模板
            ├── ARCHITECTURE.md         ← System design / 系統設計
            ├── DEPLOY.md               ← Deployment guide / 部署指南
            ├── RESILIENCE.md           ← Recovery procedures / 恢復程序
            └── TEST_REPORT.md          ← Verification results / 驗證結果
```

---

## 🔗 Related File Cross-References / 相關檔案交叉引用

### Gate #1: Merge Control / 合併控制
- 📖 Policy: [RELEASE_POLICY.md - Gate #1](RELEASE_POLICY.md#gate-1-merge-control-合併控制--most-important)
- 🔧 Setup: [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md)
- 📝 Template: [templates/CODEOWNERS](templates/CODEOWNERS)
- 📝 Template: [templates/github-workflow-validate.yml](templates/github-workflow-validate.yml)
- 🤖 Script: [scripts/validate-hardgates.sh](scripts/validate-hardgates.sh)

### Gate #2: Automated Release / 自動化釋出
- 📖 Policy: [RELEASE_POLICY.md - Gate #2](RELEASE_POLICY.md#gate-2-automated-release-pipeline-自動化釋出管道--prevents-manual-ssh-operations)
- 🔧 Setup: [SETUP_SSH_RESTRICTION.md](SETUP_SSH_RESTRICTION.md)
- 📝 Template: [templates/github-workflow-deploy.yml](templates/github-workflow-deploy.yml)
- 🤖 Script: [scripts/snapshot-release.sh](scripts/snapshot-release.sh)

### Gate #3: Least Privilege / 最小權限
- 📖 Policy: [RELEASE_POLICY.md - Gate #3](RELEASE_POLICY.md#gate-3-least-privilege-access-最小權限存取--limits-blast-radius)
- 🔧 Setup: [SETUP_LEAST_PRIVILEGE.md](SETUP_LEAST_PRIVILEGE.md)

### Gate #10: System Facts / 系統事實
- 📖 Policy: [RELEASE_POLICY.md - Gate #10](RELEASE_POLICY.md#gate-10-system-facts-checklist-系統事實檢核--eliminates-i-didnt-know)
- 📝 Template: [templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md)

### Gate #11: Documentation / 文檔記錄
- 📖 Policy: [RELEASE_POLICY.md - Gate #11](RELEASE_POLICY.md#gate-11-documentation-文件記錄)
- 📝 Templates: [templates/docs/](templates/docs/)
  - [ARCHITECTURE.md](templates/docs/ARCHITECTURE.md)
  - [DEPLOY.md](templates/docs/DEPLOY.md)
  - [RESILIENCE.md](templates/docs/RESILIENCE.md)
  - [TEST_REPORT.md](templates/docs/TEST_REPORT.md)

---

## ⚙️ Technical Details / 技術細節

### Git Workflow / Git 工作流程

**We use GitHub Flow** (not Git Flow) / **我們使用 GitHub Flow**（不是 Git Flow）

- ✅ Single long-lived branch: `main` / 單一長期分支：`main`
- ✅ Feature branches: `feature/*`, `bugfix/*`, `hotfix/*` / 功能分支
- ✅ Short-lived branches (delete after merge) / 短期分支（合併後刪除）
- ❌ No `develop` branch / 無 `develop` 分支
- ❌ No `release/*` branches / 無 `release/*` 分支

**Deployment trigger** / **部署觸發**: Git tags (v1.0.0 format) on `main` branch  
Git tags（v1.0.0 格式）在 `main` 分支上

### Enforcement Strategy / 執行策略

**Technical Controls** (cannot bypass) / **技術控制**（無法繞過）:
- GitHub branch protection (Gate #1) / GitHub 分支保護
- CI/CD pipeline blocks (Gates #1-2) / CI/CD 管道阻止
- SSH command restrictions (Gate #2) / SSH 命令限制
- Database permissions (Gate #3) / 資料庫權限
- File system permissions (Gate #3) / 檔案系統權限

**Automated Validations** (CI checks) / **自動化驗證**（CI 檢查）:
- Container/network naming (Gate #4,#8) / 容器/網路命名
- Git-tracked configuration (Gate #5) / Git 追蹤配置
- Version tags present (Gate #6) / 版本標記存在
- restart: always + healthcheck (Gate #7) / 重啟策略與健康檢查
- Documentation files exist (Gate #11) / 文檔檔案存在
- System facts complete (Gate #10) / 系統事實完整

**Manual Verifications** (reviewed in PR) / **人工驗證**（PR 中審查）:
- System facts accuracy (Gate #10) / 系統事實準確性
- Rollback procedures documented (Gate #9) / 回滾程序已記錄
- Emergency operations logged (Gate #9) / 緊急操作已記錄

---

## 🆘 Troubleshooting / 故障排除

### Common Issues / 常見問題

#### Issue 1: CI validation fails / CI 驗證失敗

**Symptom** / **症狀**: Red X on PR, cannot merge / PR 上出現紅 X，無法合併

**Solution** / **解決方案**:
```bash
# Run validation locally to see specific failures
# 在本地運行驗證以查看具體失敗
bash scripts/validate-hardgates.sh

# Fix reported issues, then push again
# 修復報告的問題，然後再次推送
git add .
git commit -m "Fix validation issues"
git push
```

**Related** / **相關**: [scripts/validate-hardgates.sh](scripts/validate-hardgates.sh)

#### Issue 2: CODEOWNERS approval required / 需要 CODEOWNERS 批准

**Symptom** / **症狀**: "Review required from code owners" / "需要程式碼所有者審查"

**Solution** / **解決方案**:
- Changes to infrastructure files require approval / 基礎設施檔案的變更需要批准
- Wait for approval from listed owner / 等待列出的所有者批准
- If urgent, contact Engineering Lead / 如果緊急，聯繫工程負責人

**Related** / **相關**: [templates/CODEOWNERS](templates/CODEOWNERS), [SETUP_BRANCH_PROTECTION.md](SETUP_BRANCH_PROTECTION.md)

#### Issue 3: Deployment blocked by missing docs / 缺少文檔導致部署被阻止

**Symptom** / **症狀**: "docs/SYSTEM_FACTS.md not found" / "未找到 docs/SYSTEM_FACTS.md"

**Solution** / **解決方案**:
```bash
# Copy and complete the checklist
# 複製並完成檢查清單
cp templates/SYSTEM_FACTS_CHECKLIST.md docs/SYSTEM_FACTS.md

# Fill in all sections (no blanks allowed)
# 填寫所有部分（不允許空白）
# Then commit and push
# 然後提交並推送
```

**Related** / **相關**: [templates/SYSTEM_FACTS_CHECKLIST.md](templates/SYSTEM_FACTS_CHECKLIST.md), [RELEASE_POLICY.md - Gate #10](RELEASE_POLICY.md#gate-10-system-facts-checklist-系統事實檢核--eliminates-i-didnt-know)

---

## 📞 Support & Contact / 支援與聯絡

### For Questions About / 關於以下問題

| Topic | Contact / Document | 主題 |
|-------|-------------------|------|
| **Deployment procedures** | [RELEASE_POLICY.md](RELEASE_POLICY.md) | 部署程序 |
| **Service documentation** | [OPS_RUNBOOK.md](OPS_RUNBOOK.md) | 服務文檔 |
| **Gate setup** | Setup guides (above) | 閘門設定 |
| **Policy changes** | Submit PR to this repo | 政策變更 |
| **Urgent production issues** | Engineering Lead | 緊急生產問題 |

### Contribution Guidelines / 貢獻指南

**To update this framework** / **更新此框架**:

1. Create feature branch / 建立功能分支
2. Make changes / 進行變更
3. Test with existing services / 使用現有服務測試
4. Submit PR with clear explanation / 提交帶有清晰說明的 PR
5. Wait for Engineering Lead approval / 等待工程負責人批准

---

## 📜 Version History / 版本歷史

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| **3.0.0** | 2026-02-02 | Optimized README with complete cross-references and bilingual content<br/>優化 README，包含完整交叉引用和雙語內容 | Ezra Wu |
| **2.0.0** | 2026-02-02 | Restructured: separated RELEASE_POLICY and OPS_RUNBOOK<br/>重組：分離 RELEASE_POLICY 和 OPS_RUNBOOK | Ezra Wu |
| **1.0.0** | 2026-02-01 | Initial framework based on Flemabus incident<br/>基於 Flemabus 事故的初始框架 | Ezra Wu |

---

## 🎓 Key Principles / 核心原則

### 1. Technical Controls Over Trust / 技術控制勝於信任

**Principle** / **原則**:  
All enforcement is automated. No reliance on human memory or discipline.  
所有執行都是自動化的。不依賴人類記憶或紀律。

**Example** / **範例**:  
GitHub technically blocks merge, not "please don't merge".  
GitHub 技術上阻止合併，而不是「請不要合併」。

### 2. Fail-Safe Defaults / 故障安全預設

**Principle** / **原則**:  
Default behavior is safe. Unsafe operations require explicit override.  
預設行為是安全的。不安全的操作需要明確覆蓋。

**Example** / **範例**:  
restart: always by default, not manual restart.  
預設為 restart: always，而非手動重啟。

### 3. Defense in Depth / 縱深防禦

**Principle** / **原則**:  
Multiple layers of protection. One failure doesn't cascade.  
多層保護。一個故障不會級聯。

**Example** / **範例**:  
Even if branch protection fails, CI still validates. Even if CI passes, CODEOWNERS still reviews.  
即使分支保護失敗，CI 仍會驗證。即使 CI 通過，CODEOWNERS 仍會審查。

### 4. No Panic Actions / 禁止恐慌操作

**Principle** / **原則**:  
Clear procedures for emergencies. No destructive panic responses.  
緊急情況的明確程序。無破壞性恐慌反應。

**Example** / **範例**:  
Rollback to last known good, never `docker-compose down`.  
回滾到最後良好狀態，絕不 `docker-compose down`。

### 5. Documentation as Code / 文檔即程式碼

**Principle** / **原則**:  
Documentation is mandatory, versioned, and validated like code.  
文檔是強制性的，像程式碼一樣版本化和驗證。

**Example** / **範例**:  
SYSTEM_FACTS.md is validated by CI, incomplete = deployment blocked.  
SYSTEM_FACTS.md 由 CI 驗證，不完整 = 部署被阻止。

---

## 💡 Final Note / 最後說明

**"Documentation is not bureaucracy. It is the foundation of reliability."**  
**「文檔不是官僚主義。它是可靠性的基礎。」**

This framework exists because a **2-week production outage** happened due to lack of these controls.  
此框架的存在是因為由於缺乏這些控制而發生了**兩週的生產中斷**。

Every gate, every check, every requirement has a **specific incident it prevents**.  
每個閘門、每個檢查、每個要求都有其**防止的特定事故**。

**This is not theoretical. This is learned from actual failure.**  
**這不是理論。這是從實際失敗中學到的。**

---

**Authorized By** / **授權人**: Ezra Wu (吳豐吉), Engineer  
**Scope** / **範圍**: Technical deployment requirements enforceable by engineers  
**Enforcement** / **執行**: Automated CI/CD checks + Technical controls
