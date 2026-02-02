# Branch Protection Setup Guide
# 分支保護設定指南

**Purpose**: Configure GitHub to enforce Hard Gates automatically  
**目的**：配置 GitHub 自動執行硬性閘門

**Time Required**: 5 minutes per repository  
**所需時間**：每個儲存庫 5 分鐘

---

## Why This Matters (為何重要)

**Without branch protection:**
- Engineers can push directly to main
- Can merge without CI green
- Can merge without code review
- Can bypass all validation

**With branch protection:**
- ✅ **CANNOT merge** without CI passing
- ✅ **CANNOT merge** without CODEOWNERS approval
- ✅ **CANNOT push** directly to main
- ✅ **CANNOT bypass** (even admins)

**This is the enforcement mechanism for all other gates.**  
**這是所有其他閘門的執行機制。**

---

## Prerequisites (先決條件)

1. **GitHub Repository** with Admin access
2. **CODEOWNERS file** already added (see `templates/CODEOWNERS`)
3. **CI workflow** already configured (see `templates/github-workflow-validate.yml`)

---

## Step-by-Step Setup (逐步設定)

### Step 1: Navigate to Repository Settings

1. Go to your repository on GitHub
2. Click **Settings** (top right)
3. Click **Branches** (left sidebar, under "Code and automation")

### Step 2: Add Branch Protection Rule

1. Click **Add branch protection rule**
2. In "Branch name pattern", enter: `main`
   - (Or `master` if your default branch is master)
   - For release branches: `release/*`

### Step 3: Configure Protection Rules

Enable the following checkboxes:

#### 3.1 Require Pull Request

- ☑️ **Require a pull request before merging**
  - ☑️ Require approvals: **1** (minimum)
  - ☑️ Dismiss stale pull request approvals when new commits are pushed
  - ☑️ Require review from Code Owners

#### 3.2 Require Status Checks

- ☑️ **Require status checks to pass before merging**
  - ☑️ Require branches to be up to date before merging
  - Search and select: **validate-hardgates** (the CI job name)
  - Search and select: **validate-docker-compose** (optional)
  - Search and select: **check-secrets** (optional)

#### 3.3 Additional Settings

- ☑️ **Require signed commits** (recommended)
- ☑️ **Require linear history** (recommended, prevents messy merge commits)
- ☑️ **Do not allow bypassing the above settings**
  - **CRITICAL**: This prevents admin override
- ☑️ **Restrict who can push to matching branches**
  - Leave empty (no one can push directly)

### Step 4: Save Rule

- Scroll to bottom
- Click **Create** (or **Save changes** if editing)

---

## Visual Configuration Checklist (視覺配置檢查清單)

```
Branch Protection Rule for: main
分支保護規則：main

☑️ Require a pull request before merging
   ☑️ Require approvals: 1
   ☑️ Dismiss stale pull request approvals
   ☑️ Require review from Code Owners

☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date
   Required status checks:
     • validate-hardgates ✅
     • validate-docker-compose ✅ (optional)
     • check-secrets ✅ (optional)

☑️ Require signed commits

☑️ Require linear history

☑️ Do not allow bypassing the above settings ⚠️ CRITICAL

☑️ Restrict who can push to matching branches
   (Empty list - no direct pushes)
```

---

## Verification (驗證)

### Test 1: Try to Push Directly to Main

```bash
# This should FAIL
git checkout main
git commit --allow-empty -m "test"
git push origin main

# Expected result:
# remote: error: GH006: Protected branch update failed
# ✅ CORRECT: Direct push blocked
```

### Test 2: Create PR Without CI Passing

1. Create branch with intentional validation failure
2. Submit PR
3. Expected result: Red X, cannot merge
4. ✅ CORRECT: Merge blocked until CI green

### Test 3: Try to Merge Without CODEOWNERS Approval

1. Create PR that modifies `docker-compose.yml`
2. Do NOT request review from CODEOWNERS
3. Try to merge
4. Expected result: "Review required from code owners"
5. ✅ CORRECT: Merge blocked until approved

---

## For Multiple Repositories (多個儲存庫)

If you manage multiple services, repeat this setup for each:

```bash
# List of repositories to configure:
# 需要配置的儲存庫列表：

☐ jasslin/flemabus
☐ jasslin/service-2
☐ jasslin/service-3
☐ jasslin/[add more]

# For each repository:
# 對每個儲存庫：
1. Add CODEOWNERS file
2. Add CI workflow
3. Configure branch protection (this guide)
4. Test enforcement
```

---

## Common Issues & Solutions (常見問題與解決方案)

### Issue 1: "Status check not found"

**Problem**: Cannot select "validate-hardgates" in status checks  
**問題**：無法在狀態檢查中選擇 "validate-hardgates"

**Solution**:  
1. Create at least one PR first
2. Wait for CI workflow to run once
3. GitHub will then show it in the list
4. Return to branch protection settings and select it

### Issue 2: Admin can still bypass

**Problem**: Admin users can click "Merge without restrictions"  
**問題**：管理員用戶可以點擊「無限制合併」

**Solution**:  
- ✅ Check "Do not allow bypassing the above settings"
- ✅ Check "Include administrators"

### Issue 3: CODEOWNERS not being enforced

**Problem**: Can merge without CODEOWNERS approval  
**問題**：可以在沒有 CODEOWNERS 批准的情況下合併

**Solution**:  
1. Verify CODEOWNERS file is at `.github/CODEOWNERS`
2. Verify "Require review from Code Owners" is checked
3. Verify GitHub username in CODEOWNERS matches exactly (case-sensitive)

### Issue 4: CI workflow not triggering

**Problem**: GitHub Actions workflow doesn't run on PR  
**問題**：GitHub Actions 工作流程不在 PR 上運行

**Solution**:  
1. Verify workflow file is at `.github/workflows/validate-hardgates.yml`
2. Check `on:` trigger includes `pull_request:`
3. Check repository has Actions enabled (Settings → Actions)
4. Check workflow syntax with: `yamllint .github/workflows/`

---

## Advanced: Automated Setup (進階：自動化設定)

For managing multiple repositories, use GitHub CLI:

```bash
# Install GitHub CLI
brew install gh  # macOS
# or: sudo apt install gh  # Linux

# Authenticate
gh auth login

# Script to configure branch protection
# (Replace OWNER and REPO)

REPO="jasslin/flemabus"

gh api repos/$REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks[strict]=true \
  --field required_status_checks[contexts][]=validate-hardgates \
  --field enforce_admins=true \
  --field required_pull_request_reviews[require_code_owner_reviews]=true \
  --field required_pull_request_reviews[required_approving_review_count]=1 \
  --field required_pull_request_reviews[dismiss_stale_reviews]=true \
  --field restrictions=null

echo "✅ Branch protection configured for $REPO"
```

---

## Maintenance (維護)

### When to Update (何時更新)

- New CI checks added → Add to required status checks
- New critical files → Update CODEOWNERS
- New branches → Add protection rules for `release/*`, `production`, etc.

### Quarterly Review (季度審查)

- Verify branch protection still enabled
- Check CODEOWNERS file is up to date
- Test enforcement with sample PR
- Review CI workflow logs for failures

---

## Emergency Override Procedure (緊急覆蓋程序)

**Only in critical production outage:**

1. **Document the incident** (why override is needed)
2. **Get approval** from Engineering Lead
3. **Temporarily disable** branch protection
4. **Merge emergency fix**
5. **Immediately re-enable** branch protection
6. **Create follow-up PR** with proper validation within 24 hours

**Log the override:**
```bash
# Create audit trail
echo "$(date): Emergency override by $(whoami)" >> emergency-overrides.log
echo "Reason: [describe incident]" >> emergency-overrides.log
echo "Commit: $(git rev-parse HEAD)" >> emergency-overrides.log
```

---

## Summary Checklist (總結檢查清單)

Before deploying any service to production:

- [ ] `.github/CODEOWNERS` file created
- [ ] `.github/workflows/validate-hardgates.yml` created
- [ ] Branch protection enabled for `main`
- [ ] Required status check: `validate-hardgates`
- [ ] Code owner review required
- [ ] "Do not allow bypassing" enabled
- [ ] Verification tests passed
- [ ] Team trained on new workflow

**Once configured, this is automatic. You don't need to check manually.**  
**配置完成後，這是自動的。你不需要手動檢查。**

---

## Next Steps (下一步)

After completing this setup:

1. **Train the team** on new PR workflow
2. **Test with a sample PR** to verify enforcement
3. **Document any exceptions** in repository README
4. **Monitor compliance** through GitHub Insights

**Questions?** See `/RELEASE_POLICY.md` for policy details.

---

**END OF GUIDE**

This technical control enforces all other gates automatically.  
No need to trust or ask for transparency — it's enforced by GitHub.

這項技術控制自動執行所有其他閘門。  
無需信任或要求透明 — GitHub 強制執行。
