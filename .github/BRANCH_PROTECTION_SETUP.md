# Branch Protection Rules Setup Guide

## Overview

Branch protection rules are essential for maintaining code quality and preventing accidental changes to critical branches. This guide provides the recommended configuration for production-ready branch protection.

## Quick Setup Instructions

### 1. Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Branches** in the left sidebar
4. Click **Add rule** or **Add branch protection rule**

### 2. Configure Rules by Branch

Apply the following configurations for each protected branch:

## Branch Protection Configurations

### Main Branch (Production)

**Branch name pattern**: `main`

#### Required Settings ✅

**Protect matching branches**:
- [x] **Require a pull request before merging**
  - [x] Require approvals: `2` (minimum)
  - [x] Dismiss stale pull request approvals when new commits are pushed
  - [x] Require review from code owners (if CODEOWNERS file exists)
  - [x] Restrict pushes that create files above the specified size limit
  - [x] Require approval of the most recent reviewable push

- [x] **Require status checks to pass before merging**
  - [x] Require branches to be up to date before merging
  - **Required status checks** (select all that apply):
    - ✅ `PR Validation Summary`
    - ✅ `Code Quality`
    - ✅ `Unit Tests`
    - ✅ `Integration Tests`
    - ✅ `Generate Documentation`
    - ✅ `Security Gate` (if security workflow enabled)
    - ✅ `Static Security Analysis`

- [x] **Require conversation resolution before merging**

- [x] **Require signed commits** (recommended for high-security environments)

- [x] **Require linear history** (prevents merge commits)

- [x] **Restrict pushes that create files above the specified size limit**
  - File size limit: `100 MB`

**Rules applied to administrators**:
- [x] **Include administrators** (recommended - even admins should follow process)

**Restrictions** (if using teams):
- **Restrict pushes to matching branches** (optional)
- Add teams/users who can push directly: `@data-team`, `@platform-team`

**Allow force pushes**: ❌ (never for production)
**Allow deletions**: ❌ (never for production)

---

### Staging Branch (Pre-production)

**Branch name pattern**: `staging`

#### Required Settings ✅

**Protect matching branches**:
- [x] **Require a pull request before merging**
  - [x] Require approvals: `1` (minimum)
  - [x] Dismiss stale pull request approvals when new commits are pushed
  - [x] Require review from code owners

- [x] **Require status checks to pass before merging**
  - [x] Require branches to be up to date before merging
  - **Required status checks**:
    - ✅ `PR Validation Summary`
    - ✅ `Code Quality`
    - ✅ `Unit Tests`
    - ✅ `Integration Tests`
    - ✅ `Generate Documentation`
    - ✅ `Security Gate`

- [x] **Require conversation resolution before merging**

- [x] **Require linear history**

**Rules applied to administrators**:
- [x] **Include administrators**

**Allow force pushes**: ❌
**Allow deletions**: ❌

---

### Develop Branch (Development)

**Branch name pattern**: `develop`

#### Required Settings ✅

**Protect matching branches**:
- [x] **Require a pull request before merging**
  - [x] Require approvals: `1` (minimum)
  - [x] Dismiss stale pull request approvals when new commits are pushed

- [x] **Require status checks to pass before merging**
  - [x] Require branches to be up to date before merging
  - **Required status checks**:
    - ✅ `PR Validation Summary`
    - ✅ `Code Quality`
    - ✅ `Unit Tests`
    - ✅ `Generate Documentation`
    - (Integration tests optional for develop - they're skipped automatically)

- [x] **Require conversation resolution before merging**

**Rules applied to administrators**:
- [ ] Include administrators (more flexibility for development)

**Allow force pushes**: ❌
**Allow deletions**: ❌

---

## Status Check Names Reference

Based on your CI workflows, here are the exact status check names to add:

### From `pull-request.yml`:
- `Detect Environment`
- `Setup Environment`
- `Code Quality`
- `Unit Tests`
- `Integration Tests` (if enabled for branch)
- `Generate Documentation`
- `PR Validation Summary`

### From `security.yml`:
- `Detect Security Context`
- `Static Security Analysis`
- `Dependency Security Scan`
- `Secret Detection`
- `License Compliance`
- `Security Gate`

### From `dependabot.yml` (for Dependabot PRs):
- `Enhanced Dependabot Testing`
- `Auto-approve Safe Updates`

## Rulesets (Advanced - GitHub Enterprise)

If using GitHub Enterprise, consider using Rulesets for more advanced control:

### Production Ruleset
```json
{
  "name": "Production Protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {"context": "PR Validation Summary"},
          {"context": "Security Gate"}
        ],
        "strict_required_status_checks_policy": true
      }
    },
    {
      "type": "require_pull_request",
      "parameters": {
        "required_approving_review_count": 2,
        "dismiss_stale_reviews": true,
        "require_code_owner_review": true,
        "require_last_push_approval": true
      }
    }
  ]
}
```

## CODEOWNERS Configuration

Create `.github/CODEOWNERS` file for automatic review requests:

```
# Global ownership
* @data-team @platform-team

# CI/CD workflows
/.github/ @platform-team @devops-team

# dbt models
/models/ @data-team @analytics-team

# Python scripts
/scripts/ @data-team @platform-team

# Security and configuration
/.secrets.baseline @security-team @platform-team
/.github/workflows/security.yml @security-team
/requirements.txt @platform-team
```

## Environment-Specific Configurations

### Development Environment
- **Purpose**: Feature development and testing
- **Protection Level**: Basic
- **Required Approvals**: 1
- **Auto-merge**: Allowed for bot updates

### Staging Environment
- **Purpose**: Pre-production validation
- **Protection Level**: Standard
- **Required Approvals**: 1-2
- **Full test suite**: Required

### Production Environment
- **Purpose**: Live system
- **Protection Level**: Maximum
- **Required Approvals**: 2+
- **All checks**: Required
- **Administrator bypass**: Discouraged

## Setup Verification

After configuring branch protection rules, verify they're working:

### 1. Test PR Creation
```bash
# Create test branch
git checkout -b test-branch-protection
echo "# Test" > test-file.md
git add test-file.md
git commit -m "test: verify branch protection"
git push origin test-branch-protection
```

### 2. Create PR and Verify
1. Create PR to protected branch
2. Verify status checks appear
3. Verify approval requirements
4. Verify merge is blocked until requirements met

### 3. Test Direct Push (Should Fail)
```bash
# This should be rejected
git checkout main
echo "Direct push test" > direct-push-test.txt
git add direct-push-test.txt
git commit -m "This should fail"
git push origin main
# Expected: Error about branch protection
```

## Troubleshooting

### Common Issues

**Status checks not appearing**:
- Verify workflow names match exactly
- Check if workflows are running on the correct events
- Ensure workflows have completed at least once successfully

**Required reviews not enforcing**:
- Check if CODEOWNERS file exists and is valid
- Verify team/user permissions
- Ensure "Include administrators" is checked if admin is testing

**Status checks showing as "Expected" but never running**:
- Workflow might not trigger for the branch type
- Check workflow `on:` triggers
- Verify workflow file syntax is correct

### Fixing Branch Protection

If you need to temporarily bypass protection (emergency only):

1. **Repository Admins**: Can temporarily disable rules
2. **Emergency Process**:
   - Disable protection
   - Make critical fix
   - Re-enable protection immediately
   - Create follow-up PR to document changes

### Audit and Monitoring

**Regular Checks**:
- Review protection settings monthly
- Monitor bypass attempts
- Update required status checks when workflows change
- Review and update CODEOWNERS as team changes

**GitHub API for Automation**:
```bash
# Get current branch protection
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/branches/main/protection

# Update branch protection programmatically
curl -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/branches/main/protection \
  -d @protection-config.json
```

## Security Considerations

### Required for Production
1. **Signed commits**: Verify authenticity
2. **Required status checks**: Ensure code quality
3. **Required reviews**: Prevent unilateral changes
4. **Conversation resolution**: Ensure issues are addressed
5. **Administrator inclusion**: Even admins follow process
6. **No force pushes**: Preserve history
7. **No deletions**: Prevent accidental branch removal

### Recommended Additional Security
1. **Branch scanning**: Enable secret scanning
2. **Vulnerability alerts**: Enable Dependabot alerts
3. **Security advisories**: Monitor and respond
4. **Audit logs**: Review branch protection changes

## Integration with CI Workflows

Your branch protection rules integrate with the CI workflows as follows:

**Pull Request Flow**:
1. Developer creates PR
2. `pull-request.yml` workflow runs
3. Status checks report to GitHub
4. Branch protection evaluates all required checks
5. Merge becomes available only when all requirements met

**Security Integration**:
1. `security.yml` runs on PR creation
2. Security gate blocks merge if issues found
3. Issues must be resolved before merge allowed
4. Different thresholds for different environments

**Dependabot Integration**:
1. Dependabot creates automated PRs
2. `dependabot.yml` workflow runs enhanced testing
3. Safe updates can auto-merge
4. Major updates require manual review

This branch protection setup ensures code quality, security, and proper review processes while maintaining development velocity.
