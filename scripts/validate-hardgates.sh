#!/bin/bash
# Hard Gates Validation Script
# Lessons from the 2-week Flemabus outage incident
# 
# Purpose: Automated checks that prevent:
# - Network naming conflicts
# - Accidental docker-compose down in wrong directory  
# - Inability to rollback
# - Service persistence failures
# - Knowledge concentration (single point of failure)

set -e

echo "=========================================="
echo "Hard Gates Validation"
echo "From: Jasslin Production Service Standards"
echo ""
echo "NOTE: Gate #1 (Merge Control) is enforced by GitHub"
echo "      This script validates Gates #2-#6"
echo "=========================================="
echo ""

FAILED=0

# ============================================
# Gate #1: Merge Control
# ============================================
# Note: This gate is enforced by GitHub branch protection + CODEOWNERS + CI
# We just verify the files exist here

echo "📋 Gate #1: Merge Control (enforced by GitHub)"
echo "  Checking for required enforcement files..."

if [ -f ".github/CODEOWNERS" ]; then
    echo "  ✅ PASS: .github/CODEOWNERS exists"
else
    echo "  ⚠️  WARN: .github/CODEOWNERS not found"
    echo "      This file is needed for code review enforcement"
    echo "      Copy from: templates/CODEOWNERS"
fi

if [ -f ".github/workflows/validate-hardgates.yml" ] || [ -f ".github/workflows/validate.yml" ]; then
    echo "  ✅ PASS: GitHub Actions workflow exists"
else
    echo "  ⚠️  WARN: GitHub Actions workflow not found"
    echo "      This file is needed for CI automation"
    echo "      Copy from: templates/github-workflow-validate.yml"
fi

echo ""

# ============================================
# Gate #2: Automated Release Pipeline
# ============================================
echo "📋 Gate #2: Automated Release Pipeline (prevents manual SSH operations)"
echo "  Checking for deployment automation..."

# Check 2.1: Production deployment workflow exists
if [ -f ".github/workflows/deploy-production.yml" ] || [ -f ".github/workflows/deploy.yml" ]; then
    echo "  ✅ PASS: Deployment workflow exists"
    
    # Check 2.2: Workflow triggers on tags only (not manual)
    DEPLOY_WORKFLOW=$(ls .github/workflows/deploy*.yml 2>/dev/null | head -1)
    if [ -n "$DEPLOY_WORKFLOW" ]; then
        if grep -q "tags:" "$DEPLOY_WORKFLOW"; then
            echo "  ✅ PASS: Workflow triggers on tags (prevents manual deployment)"
        else
            echo "  ⚠️  WARN: Workflow should only trigger on tags"
            echo "      This ensures deployments are version-controlled"
        fi
    fi
else
    echo "  ⚠️  WARN: No deployment workflow found"
    echo "      Production deployments should go through automated pipeline"
    echo "      Copy from: templates/github-workflow-deploy.yml"
fi

# Check 2.3: Snapshot script present
if [ -f "scripts/snapshot-release.sh" ]; then
    echo "  ✅ PASS: Release snapshot script exists"
else
    echo "  ⚠️  WARN: scripts/snapshot-release.sh not found"
    echo "      Snapshot script creates rollback artifacts"
    echo "      Copy from: documentation-management/scripts/snapshot-release.sh"
fi

echo ""

# ============================================
# Gate #3: Environment Isolation
# ============================================
echo "📋 Gate #3: Environment Isolation (prevents network conflicts)"

# Check 1.1: No generic network names
echo "  Checking for generic network names..."
if grep -qE "^\s*(app-network|default|web|backend|frontend|db-network):" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: Generic network name found"
    echo "     Generic names cause conflicts between deployments"
    echo "     Use: \${PROJECT_NAME}-network instead"
    FAILED=1
else
    echo "  ✅ PASS: No generic network names"
fi

# Check 1.2: Container names must exist
echo "  Checking container names..."
if ! grep -q "container_name:" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: No container_name definitions"
    echo "     Without names, can't identify which containers belong to which project"
    FAILED=1
else
    echo "  ✅ PASS: Container names defined"
fi

# Check 1.3: Custom networks defined
echo "  Checking custom network definitions..."
if ! grep -q "^networks:" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: No custom networks defined"
    echo "     Using default network risks conflicts"
    FAILED=1
else
    echo "  ✅ PASS: Custom networks defined"
fi

echo ""

# ============================================
# Gate #4: Git-Tracked Configuration
# ============================================
echo "📋 Gate #4: Git-Tracked Configuration (prevents accidental operations)"

# Check 2.1: docker-compose.yml in git
echo "  Checking if docker-compose.yml is tracked in git..."
if ! git ls-files docker-compose.yml 2>/dev/null | grep -q docker-compose.yml; then
    echo "  ❌ FAIL: docker-compose.yml not tracked in git"
    echo "     Without git tracking, can't verify which directory you're in"
    FAILED=1
else
    echo "  ✅ PASS: docker-compose.yml tracked in git"
fi

# Check 2.2: PROJECT_NAME in .env
echo "  Checking PROJECT_NAME in .env..."
if [ -f .env ]; then
    if ! grep -q "^PROJECT_NAME=" .env; then
        echo "  ❌ FAIL: Missing PROJECT_NAME in .env"
        echo "     PROJECT_NAME helps identify which deployment you're working on"
        FAILED=1
    else
        PROJECT=$(grep "^PROJECT_NAME=" .env | cut -d= -f2)
        echo "  ✅ PASS: PROJECT_NAME=$PROJECT"
    fi
else
    echo "  ⚠️  WARN: .env file not found (may not be committed)"
fi

echo ""

# ============================================
# Gate #5: Rollback Capability
# ============================================
echo "📋 Gate #5: Rollback Capability (prevents 2-week recovery)"

# Check 3.1: Current commit must be tagged
echo "  Checking if HEAD is tagged..."
if ! git describe --exact-match HEAD 2>/dev/null; then
    echo "  ❌ FAIL: HEAD commit not tagged"
    echo "     Without tags, can't rollback to previous working version"
    echo "     Fix: git tag -a v1.0.0 -m 'Release' && git push origin v1.0.0"
    FAILED=1
else
    TAG=$(git describe --exact-match HEAD 2>/dev/null)
    echo "  ✅ PASS: Tagged as $TAG"
    
    # Check 3.2: Tag must follow version format
    if ! echo "$TAG" | grep -Eq "^v[0-9]+\.[0-9]+\.[0-9]+$"; then
        echo "  ❌ FAIL: Tag format incorrect (must be v1.0.0)"
        FAILED=1
    else
        echo "  ✅ PASS: Tag format correct"
    fi
fi

echo ""

# ============================================
# Gate #6: Service Persistence
# ============================================
echo "📋 Gate #6: Service Persistence (survives reboot)"

# Check 4.1: restart policies
echo "  Checking restart policies..."
if ! grep -q "restart: always" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: No 'restart: always' found"
    echo "     Services won't restart after reboot"
    FAILED=1
else
    echo "  ✅ PASS: restart: always configured"
fi

# Check 4.2: Health checks
echo "  Checking health checks..."
if ! grep -q "healthcheck:" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: No healthcheck configured"
    echo "     Can't verify service is actually working after restart"
    FAILED=1
else
    echo "  ✅ PASS: healthcheck configured"
fi

echo ""

# ============================================
# Gate #7: Documentation
# ============================================
echo "📋 Gate #7: Documentation (eliminates knowledge single-point-of-failure)"

# Check if running in service repo (has docs/) or this repo (has templates/docs/)
if [ -d "docs" ]; then
    DOCS_DIR="docs"
elif [ -d "templates/docs" ]; then
    echo "  ⚠️  NOTE: Running in documentation-management repo"
    echo "      This check validates service repositories"
    echo "      Skipping documentation check for this repo"
    DOCS_DIR=""
else
    echo "  ❌ FAIL: Neither docs/ nor templates/docs/ found"
    FAILED=1
    DOCS_DIR=""
fi

if [ -n "$DOCS_DIR" ]; then
    DOCS=(
        "$DOCS_DIR/ARCHITECTURE.md"
        "$DOCS_DIR/DEPLOY.md"
        "$DOCS_DIR/RESILIENCE.md"
        "$DOCS_DIR/TEST_REPORT.md"
    )

    for doc in "${DOCS[@]}"; do
        echo "  Checking $doc..."
        if [ ! -f "$doc" ]; then
            echo "  ❌ FAIL: $doc not found"
            FAILED=1
        else
            echo "  ✅ PASS: $doc exists"
        fi
    done
fi

echo ""
echo "=========================================="

if [ $FAILED -eq 1 ]; then
    echo "❌ HARD GATES FAILED (Gates #3-#7)"
    echo "   Pull request will be BLOCKED by CI"
    echo ""
    echo "What each gate prevents:"
    echo "  - Gate #1: Merge Control (enforced by GitHub branch protection)"
    echo "  - Gate #2: Automated Release (enforced by deployment pipeline)"
    echo "  - Gate #3: Network conflicts (generic names)"
    echo "  - Gate #4: Accidental shutdowns (wrong-directory operations)"
    echo "  - Gate #5: 2-week recovery (enables 30-second rollback)"
    echo "  - Gate #6: Manual restart after reboot"
    echo "  - Gate #7: Knowledge single-point-of-failure"
    echo ""
    echo "For detailed requirements, see:"
    echo "https://github.com/jasslin/documentation-management/blob/main/RELEASE_POLICY.md"
    exit 1
else
    echo "✅ ALL HARD GATES PASSED (Gates #3-#7)"
    echo ""
    echo "Gates #1-2 will be enforced when you deploy:"
    echo ""
    echo "Gate #1 (Merge Control) — GitHub enforces:"
    echo "  1. Submit pull request"
    echo "  2. Wait for CODEOWNERS approval"
    echo "  3. Wait for CI green checkmark"
    echo "  4. Merge to main"
    echo ""
    echo "Gate #2 (Automated Release) — Deployment pipeline enforces:"
    echo "  1. Create git tag: git tag -a v1.2.3 -m 'Release'"
    echo "  2. Push tag: git push origin v1.2.3"
    echo "  3. GitHub Actions automatically deploys"
    echo "  4. Manual SSH docker-compose operations are FORBIDDEN"
    echo ""
    echo "Result: Cannot bypass — technical controls enforce all gates."
    exit 0
fi
