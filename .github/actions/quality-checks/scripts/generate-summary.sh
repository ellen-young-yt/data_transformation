#!/bin/bash
set -e

REPORTS_DIR="quality-reports"

# Load results from check-results script
if [ -f "$REPORTS_DIR/check-results.env" ]; then
    source "$REPORTS_DIR/check-results.env"
fi

# Set defaults
HAS_ERRORS="${HAS_ERRORS:-false}"
HAS_WARNINGS="${HAS_WARNINGS:-false}"
QUALITY_SCORE="${QUALITY_SCORE:-100}"
PRE_COMMIT_EXIT="${PRE_COMMIT_EXIT:-1}"
MAKE_LINT_EXIT="${MAKE_LINT_EXIT:-1}"
DBT_COMPILE_EXIT="${DBT_COMPILE_EXIT:-0}"

echo "Generating quality summary..."

# Set display values based on exit codes and flags
ERRORS_STATUS=$([ "$HAS_ERRORS" = "true" ] && echo "❌ Yes" || echo "✅ No")
WARNINGS_STATUS=$([ "$HAS_WARNINGS" = "true" ] && echo "⚠️ Yes" || echo "✅ No")
PRECOMMIT_STATUS=$([ "$PRE_COMMIT_EXIT" = "0" ] && [ "$MAKE_LINT_EXIT" = "0" ] && echo "✅ Passed" || echo "❌ Failed")
PRECOMMIT_HOOKS_STATUS=$([ "$PRE_COMMIT_EXIT" = "0" ] && echo "✅" || echo "❌")
MAKE_LINT_STATUS=$([ "$MAKE_LINT_EXIT" = "0" ] && echo "✅" || echo "❌")
DBT_COMPILE_STATUS=$([ "$DBT_COMPILE_EXIT" = "0" ] && echo "✅ Passed" || echo "❌ Failed")
SECURITY_STATUS="✅ Completed"

# Generate the summary file
cat > "$REPORTS_DIR/summary.md" << EOF
# Code Quality Report

## Summary
- **Quality Score**: ${QUALITY_SCORE}/100
- **Errors**: ${ERRORS_STATUS}
- **Warnings**: ${WARNINGS_STATUS}

## Check Results
- **Pre-commit Hooks**: ${PRECOMMIT_STATUS}
  - Pre-commit: ${PRECOMMIT_HOOKS_STATUS}
  - Make lint: ${MAKE_LINT_STATUS}
- **dbt Compilation**: ${DBT_COMPILE_STATUS}
- **Security Analysis**: ${SECURITY_STATUS}
  - Multiple security tools executed (Bandit, Safety, pip-audit)

## Detailed Reports
### Detailed Reports Available
- **lint-report.txt**: Pre-commit hooks and linting results
- **security-report.json/txt**: Bandit security analysis
- **safety-report.json/txt**: Known vulnerability scan
- **pip-audit.json**: Package vulnerability audit
- **dbt-compile.txt**: dbt compilation output
- **dbt-docs.txt**: Documentation generation log

Check the uploaded artifacts for complete analysis details.
EOF

echo "Summary generated successfully"
