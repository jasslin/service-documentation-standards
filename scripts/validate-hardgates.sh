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
# Gate #3: Least Privilege Access
# ============================================
echo "📋 Gate #3: Least Privilege Access (limits blast radius)"
echo "  Checking access control documentation..."

# Check 3.1: Documentation mentions access tiers
if [ -f "docs/DEPLOY.md" ]; then
    if grep -qi "vendor.*access\|permission.*tier\|read-only" docs/DEPLOY.md; then
        echo "  ✅ PASS: Access control documented in DEPLOY.md"
    else
        echo "  ⚠️  WARN: DEPLOY.md should document access tiers"
        echo "      Specify: vendor read-only access, no sudo, database SELECT-only"
    fi
fi

# Check 3.2: Database user creation scripts exist
if [ -f "scripts/create-readonly-user.sql" ] || grep -rq "CREATE USER.*readonly" . 2>/dev/null; then
    echo "  ✅ PASS: Read-only database user setup found"
else
    echo "  ⚠️  WARN: Consider including read-only database user setup"
    echo "      See: SETUP_LEAST_PRIVILEGE.md for SQL templates"
fi

# Check 3.3: No hardcoded admin credentials in compose
if grep -qi "POSTGRES_USER=postgres\|MYSQL_USER=root" docker-compose.yml 2>/dev/null; then
    echo "  ⚠️  WARN: Default admin users in docker-compose.yml"
    echo "      Use application-specific users with limited privileges"
fi

echo ""

# ============================================
# Gate #4: Environment Isolation
# ============================================
echo "📋 Gate #4: Environment Isolation (prevents network conflicts)"

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
# Gate #5: Git-Tracked Configuration
# ============================================
echo "📋 Gate #5: Git-Tracked Configuration (prevents accidental operations)"

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
# Gate #6: Rollback Capability
# ============================================
echo "📋 Gate #6: Rollback Capability (prevents 2-week recovery)"

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
# Gate #7: Service Persistence
# ============================================
echo "📋 Gate #7: Service Persistence (survives reboot)"

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
# Gate #8: Environment Isolation Standard
# ============================================
echo "📋 Gate #8: Environment Isolation (prevents conflicts)"

# Check 8.1: Compose project name defined
if grep -q "^name:" docker-compose.yml 2>/dev/null; then
    PROJECT_NAME=$(grep "^name:" docker-compose.yml | awk '{print $2}')
    echo "  ✅ PASS: Project name defined: $PROJECT_NAME"
elif grep -q "^COMPOSE_PROJECT_NAME=" .env 2>/dev/null; then
    PROJECT_NAME=$(grep "^COMPOSE_PROJECT_NAME=" .env | cut -d= -f2)
    echo "  ✅ PASS: Project name in .env: $PROJECT_NAME"
else
    echo "  ❌ FAIL: No project name defined"
    echo "      Add 'name: project-env' to docker-compose.yml"
    echo "      Or COMPOSE_PROJECT_NAME=project-env to .env"
    FAILED=1
fi

# Check 8.2: No generic network names
if grep -Eq "^\s*(default|app-network|backend|frontend|web|db-network):" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: Generic network names found"
    echo "      Use project-specific names: project-env-backend"
    FAILED=1
else
    echo "  ✅ PASS: No generic network names"
fi

# Check 8.3: Container names include project prefix
if docker-compose config 2>/dev/null | grep -q "container_name:"; then
    if [ -n "$PROJECT_NAME" ] && ! docker-compose config 2>/dev/null | grep "container_name:" | grep -q "$PROJECT_NAME"; then
        echo "  ⚠️  WARN: Container names should include project name"
    else
        echo "  ✅ PASS: Container names include project prefix"
    fi
fi

# Check 8.4: Not using default network
if ! grep -q "^networks:" docker-compose.yml 2>/dev/null; then
    echo "  ❌ FAIL: No custom networks defined (using default)"
    echo "      Define custom networks in docker-compose.yml"
    FAILED=1
else
    echo "  ✅ PASS: Custom networks defined"
fi

echo ""

# ============================================
# Gate #9: Rollback & No Panic Actions
# ============================================
echo "📋 Gate #9: Rollback & No Panic Actions (prevents escalation)"

# Check 9.1: Rollback procedure documented
if [ -f "docs/RESILIENCE.md" ]; then
    if grep -qi "rollback\|last known good" docs/RESILIENCE.md; then
        echo "  ✅ PASS: Rollback procedure documented"
    else
        echo "  ⚠️  WARN: RESILIENCE.md should document rollback procedure"
    fi
fi

# Check 9.2: Git tags exist for rollback
TAG_COUNT=$(git tag -l | wc -l)
if [ "$TAG_COUNT" -gt 0 ]; then
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
    echo "  ✅ PASS: Git tags available for rollback (latest: $LATEST_TAG)"
else
    echo "  ⚠️  WARN: No git tags found"
    echo "      Create version tags for rollback capability"
fi

# Check 9.3: Backup script exists
if [ -f "scripts/backup-current-state.sh" ] || grep -q "backup" docker-compose.yml 2>/dev/null; then
    echo "  ✅ PASS: Backup mechanism found"
else
    echo "  ⚠️  WARN: No backup script found"
    echo "      Consider adding scripts/backup-current-state.sh"
fi

echo ""

# ============================================
# Gate #10: System Facts Checklist
# ============================================
echo "📋 Gate #10: System Facts Checklist (eliminates assumptions)"

# Check 10.1: Checklist exists
if [ -f "docs/SYSTEM_FACTS.md" ]; then
    echo "  ✅ PASS: SYSTEM_FACTS.md exists"
    
    # Check 10.2: No placeholders
    if grep -q "_____________" docs/SYSTEM_FACTS.md; then
        echo "  ❌ FAIL: Checklist contains unfilled fields"
        echo "      Complete all sections before deployment"
        FAILED=1
    else
        echo "  ✅ PASS: No unfilled fields"
    fi
    
    # Check 10.3: No TBD/TODO
    if grep -Eqi "TBD|TODO|FIXME" docs/SYSTEM_FACTS.md; then
        echo "  ❌ FAIL: Checklist contains placeholder values (TBD/TODO)"
        FAILED=1
    else
        echo "  ✅ PASS: No placeholder values"
    fi
    
    # Check 10.4: Database instances documented
    if ! grep -q "Database #1" docs/SYSTEM_FACTS.md; then
        echo "  ❌ FAIL: Database instances not documented"
        FAILED=1
    else
        echo "  ✅ PASS: Database instances documented"
    fi
    
    # Check 10.5: Vendor sign-off
    if grep -q "Signature:" docs/SYSTEM_FACTS.md; then
        echo "  ✅ PASS: Sign-off section present"
    else
        echo "  ⚠️  WARN: No sign-off section found"
    fi
    
else
    echo "  ❌ FAIL: docs/SYSTEM_FACTS.md not found"
    echo "      Copy from templates/SYSTEM_FACTS_CHECKLIST.md"
    echo "      Complete all sections before deployment"
    FAILED=1
fi

echo ""

# ============================================
# Gate #11: Documentation
# ============================================
echo "📋 Gate #11: Documentation (eliminates knowledge single-point-of-failure)"

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
    echo "❌ HARD GATES FAILED"
    echo "   Pull request will be BLOCKED by CI"
    echo ""
    echo "What each gate prevents:"
    echo "  - Gate #1: Merge Control (enforced by GitHub)"
    echo "  - Gate #2: Automated Release (enforced by pipeline)"
    echo "  - Gate #3: Least Privilege (enforced on servers)"
    echo "  - Gate #4: Environment isolation (CI check)"
    echo "  - Gate #5: Git-tracked config (CI check)"
    echo "  - Gate #6: Rollback capability (CI check)"
    echo "  - Gate #7: Service persistence (CI check)"
    echo "  - Gate #8: Network conflicts (prevents 2-week outage)"
    echo "  - Gate #9: Panic actions (prevents escalation)"
    echo "  - Gate #10: System facts (eliminates 'I didn't know')"
    echo "  - Gate #11: Documentation (eliminates knowledge single-point)"
    echo ""
    echo "For detailed requirements, see:"
    echo "https://github.com/jasslin/documentation-management/blob/main/RELEASE_POLICY.md"
    exit 1
else
    echo "✅ ALL HARD GATES PASSED"
    echo ""
    echo "Enforcement mechanisms will activate during deployment:"
    echo ""
    echo "Gate #1 (Merge Control) — GitHub enforces:"
    echo "  • PR approval from CODEOWNERS required"
    echo "  • CI must pass before merge"
    echo ""
    echo "Gate #2 (Automated Release) — Pipeline enforces:"
    echo "  • Only git tags trigger deployment"
    echo "  • Manual SSH operations blocked"
    echo ""
    echo "Gate #3 (Least Privilege) — Servers enforce:"
    echo "  • Vendors: read-only access only"
    echo "  • All actions logged"
    echo ""
    echo "Gate #8 (Environment Isolation) — Prevents:"
    echo "  • Network name conflicts"
    echo "  • Port collisions"
    echo "  • Resource interference"
    echo ""
    echo "Gate #9 (No Panic Actions) — Requires:"
    echo "  • Rollback to last known good (not docker-compose down)"
    echo "  • Emergency operations must be logged"
    echo ""
    echo "Gate #10 (System Facts) — Eliminates:"
    echo "  • 'I didn't know there were 4 databases'"
    echo "  • Wrong topology assumptions"
    echo "  • Incomplete understanding"
    echo ""
    echo "Result: Technical controls prevent incident recurrence."
    exit 0
fi
