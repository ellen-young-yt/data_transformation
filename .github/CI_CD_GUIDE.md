# CI/CD Pipeline Guide

## Overview

This project uses a production-ready CI/CD pipeline with GitHub Actions that provides:

- ✅ **Automated testing** and quality checks
- 🔒 **Security scanning** with PR blocking
- 🚀 **Environment-aware deployments**
- 🔄 **Rollback capabilities**
- 📦 **Automated dependency updates**
- 📊 **Comprehensive monitoring** and notifications

## Branch Strategy

| Branch | Environment | Purpose | Auto-Deploy |
|--------|-------------|---------|-------------|
| `main` | Production | Stable releases | ✅ Yes |
| `staging` | Staging | Pre-production testing | ✅ Yes |
| `develop` | Development | Feature integration | ✅ Yes |

## Workflows Overview

### 1. Pull Request Validation (`pull-request.yml`)

**Triggers**: Pull requests to `main`, `staging`, `develop`

**What it does**:
- 🔍 **Code quality checks** (linting, formatting, pre-commit hooks)
- 🧪 **Unit tests** (fast, no external dependencies)
- 🔗 **Integration tests** (skipped for dev PRs to save time)
- 📚 **Documentation generation**
- 📊 **Comprehensive reporting** with pass/fail status

**Environment-specific behavior**:
- **PRs to `main`**: Strict quality checks + full integration tests
- **PRs to `staging`**: Standard checks + integration tests
- **PRs to `develop`**: Basic checks, integration tests skipped

**Failure handling**: PRs cannot be merged if quality checks or unit tests fail.

### 2. Deployment Pipeline (`deploy.yml`)

**Triggers**:
- Push to `main`, `staging`, `develop`
- Manual workflow dispatch

**What it does**:
1. 🏗️ **Pre-deployment validation** (quality checks, compilation)
2. 🐳 **Docker image build** and push to ECR
3. 🚀 **dbt model deployment** (run models + tests)
4. 🧪 **Post-deployment integration tests**
5. 📈 **Deployment monitoring** and notifications

**Rollback Support**:
- Manual rollback via workflow dispatch
- Automatic issue creation if rollback fails
- Full audit trail and notifications

### 3. Security Scanning (`security.yml`)

**Triggers**:
- Daily scheduled scan (2 AM UTC)
- Push to any main branch
- Pull requests (with PR blocking logic)

**What it does**:
- 🛡️ **Static Application Security Testing** (Bandit, Semgrep)
- 📦 **Dependency vulnerability scanning** (Safety, pip-audit)
- 🔍 **Secret detection** (detect-secrets, TruffleHog)
- ⚖️ **License compliance** checking
- 🚫 **PR blocking** for critical/high security issues in production environments

**Security Thresholds**:
- **Production**: High severity issues block deployment
- **Staging**: Medium severity issues block deployment
- **Development**: Only critical issues block (warnings allowed)

### 4. Dependabot Automation (`dependabot.yml`)

**What it does**:
- 📅 **Weekly automated dependency updates**
- 🤖 **Auto-merge** for safe updates (security patches, minor versions)
- 🧪 **Enhanced testing** for dependency changes
- 👥 **Manual review** required for major updates

**Auto-merge criteria**:
- Security updates: ✅ Always
- Patch updates: ✅ Always
- Minor updates: ✅ For safe packages only
- Major updates: ❌ Manual review required

## Custom GitHub Actions

### Core Actions

#### `detect-environment`
Centralizes environment detection logic:
```yaml
- uses: ./.github/actions/detect-environment
  with:
    manual-environment: 'prod'  # Optional override
```

**Outputs**: `environment`, `dbt-target`, `is-production`, `aws-region`, etc.

#### `setup-complete`
One-stop setup for Python + dbt + AWS:
```yaml
- uses: ./.github/actions/setup-complete
  with:
    python-version: '3.12'
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    environment: 'dev'
```

#### `quality-checks`
Comprehensive code quality validation:
```yaml
- uses: ./.github/actions/quality-checks
  with:
    fail-on-warnings: 'false'
    environment: 'dev'
```

#### `handle-results`
Standardized error/warning classification:
```yaml
- uses: ./.github/actions/handle-results
  with:
    environment: 'prod'
    context: 'pr'
    quality-check-exit-code: ${{ steps.quality.outputs.exit-code }}
    allow-warnings: 'true'
```

## Usage Guide

### Making Changes

1. **Create feature branch** from `develop`
2. **Make your changes** following code standards
3. **Run pre-commit hooks**: `pre-commit run --all-files`
4. **Create PR to `develop`** - automated validation runs
5. **Address any issues** flagged by CI
6. **Merge when approved** - auto-deploys to dev environment

### Promoting to Higher Environments

1. **Staging**: Create PR from `develop` → `staging`
   - Full testing including integration tests
   - Security scans with medium threshold

2. **Production**: Create PR from `staging` → `main`
   - Strictest validation (high security threshold)
   - Full test suite required to pass
   - Manual approval recommended

### Rolling Back Deployments

If you need to rollback a deployment:

1. **Go to Actions** → **Deploy to Environment** workflow
2. **Click "Run workflow"**
3. **Configure rollback**:
   - Environment: Choose target environment
   - Rollback to commit: Enter commit SHA to rollback to
   - Rollback reason: Explain why (required)
4. **Run** - automated rollback with full validation

**Example**:
```
Environment: prod
Rollback to commit: abc1234
Rollback reason: Critical bug in user authentication affecting login
```

### Emergency Procedures

#### Security Incident
If critical security issues are found:
1. Security workflow automatically creates GitHub issue
2. Review findings in Security tab
3. Create hotfix branch immediately
4. Deploy through normal PR process (security gates will block until fixed)

#### Failed Deployment
If deployment fails:
1. Check workflow logs for specific errors
2. If in production, consider immediate rollback
3. Fix issues in development environment first
4. Re-deploy through standard process

#### Production Rollback Failure
If rollback fails (rare):
1. Automated GitHub issue is created with "urgent" label
2. Manual intervention required - check issue for specific steps
3. May require direct infrastructure access

## Configuration

### Required Secrets

| Secret | Purpose | Required For |
|--------|---------|--------------|
| `AWS_ACCESS_KEY_ID` | AWS authentication | All workflows |
| `AWS_SECRET_ACCESS_KEY` | AWS authentication | All workflows |
| `GITHUB_TOKEN` | GitHub API access | Auto-generated |
| `SEMGREP_APP_TOKEN` | Enhanced security scanning | Optional |

### Environment Variables

All workflows use centralized environment detection. Key variables:

- `ENVIRONMENT`: `dev`, `staging`, `prod`
- `DBT_TARGET`: `dev`, `test`, `prod`
- `AWS_REGION`: `us-east-2`
- `USE_AWS_SECRETS`: `true`

### Pre-commit Configuration

Pre-commit hooks run locally and in CI:

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

**Included checks**:
- Python: black, isort, flake8, mypy, bandit
- SQL: SQLFluff with dbt templating
- General: YAML validation, trailing whitespace, secrets detection
- Project-specific: dbt compilation, environment validation

## Monitoring and Notifications

### GitHub Issues
Automated issues created for:
- Critical security findings
- Failed rollbacks requiring manual intervention
- Dependency update failures

### Workflow Summaries
Each workflow provides detailed summaries with:
- ✅/❌ Status indicators
- 📊 Metrics and counts
- 🔗 Links to detailed reports
- 📋 Next steps and recommendations

### Artifacts
Important artifacts retained:
- **Test reports**: 7-30 days
- **Security reports**: 30 days
- **Deployment logs**: 90 days
- **dbt documentation**: 30 days

## Best Practices

### Development Workflow
1. **Always work in feature branches** - never commit directly to main branches
2. **Run pre-commit hooks locally** before pushing
3. **Write tests** for new functionality
4. **Update documentation** when changing behavior
5. **Use descriptive commit messages** following conventional commits

### Security
1. **Never commit secrets** - use environment variables/secrets
2. **Review security scan results** regularly
3. **Update dependencies** promptly (Dependabot helps)
4. **Follow principle of least privilege** for AWS access

### Deployment
1. **Test in lower environments first** (dev → staging → prod)
2. **Monitor deployments** and check logs
3. **Have rollback plan ready** for production deployments
4. **Coordinate with team** for production changes

### Troubleshooting

#### Common Issues

**"Pre-commit hooks failing"**:
- Run `pre-commit run --all-files` locally
- Check specific tool outputs (black, flake8, etc.)
- Update hooks: `pre-commit autoupdate`

**"dbt compilation errors"**:
- Check dbt syntax and model references
- Verify profiles.yml configuration
- Ensure all required environment variables are set

**"Security scan blocking PR"**:
- Review security findings in workflow logs
- Update vulnerable dependencies
- For false positives, update security tool configuration

**"AWS authentication errors"**:
- Verify AWS secrets are correctly configured
- Check IAM permissions for dbt operations
- Ensure AWS region matches configuration

**"Integration tests failing"**:
- Check if test data is available in target environment
- Verify database connections and permissions
- Review test expectations vs. actual data

#### Getting Help

1. **Check workflow logs** first - they contain detailed error information
2. **Review this documentation** for configuration guidance
3. **Check recent GitHub issues** - similar problems may have been resolved
4. **Create GitHub issue** with detailed error information if stuck

## Advanced Configuration

### Customizing Security Thresholds

Edit `.github/workflows/security.yml` to adjust severity thresholds:

```yaml
# For stricter security in all environments
severity-threshold: 'medium'  # vs. 'high' for production only
```

### Adding New Environments

1. Update `detect-environment` action with new branch mapping
2. Add environment-specific configuration in deployment workflow
3. Update documentation and branch protection rules

### Custom Quality Checks

Add new checks to `quality-checks` action or pre-commit configuration:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: custom-check
      name: Custom validation
      entry: python scripts/custom_validator.py
      language: python
```

This CI/CD pipeline is designed for reliability, security, and ease of use. For questions or improvements, please create a GitHub issue or reach out to the development team.
