#!/bin/bash
set -e

REPORTS_DIR="quality-reports"

# Function to safely get integer value from variable
safe_int() {
    local value="$1"
    local default="${2:-0}"

    # Strip whitespace and newlines
    value=$(echo "$value" | tr -d ' \n\r\t')

    # Check if it's a valid integer
    if [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Function to safely parse JSON integer
parse_json_int() {
    local file="$1"
    local jq_expr="$2"
    local default="${3:-0}"

    if [ -f "$file" ]; then
        local result
        result=$(jq "$jq_expr" "$file" 2>/dev/null | head -1)
        safe_int "$result" "$default"
    else
        echo "$default"
    fi
}

echo "Analyzing check results..."

has_errors="false"
has_warnings="false"

# Check pre-commit results with detailed analysis
PRE_COMMIT_EXIT="${PRE_COMMIT_EXIT:-1}"
MAKE_LINT_EXIT="${MAKE_LINT_EXIT:-1}"

if [ "$PRE_COMMIT_EXIT" != "0" ] || [ "$MAKE_LINT_EXIT" != "0" ]; then
    has_errors="true"
    echo "❌ Pre-commit checks failed with critical errors"
    echo "  - Pre-commit hooks exit: $PRE_COMMIT_EXIT"
    echo "  - Make lint exit: $MAKE_LINT_EXIT"
else
    echo "✅ All pre-commit checks passed"
fi

# Check dbt compilation
DBT_COMPILE_EXIT="${DBT_COMPILE_EXIT:-0}"
if [ "$DBT_COMPILE_EXIT" != "0" ]; then
    has_errors="true"
    echo "❌ dbt compilation failed"
else
    echo "✅ dbt compilation successful"
fi

# Enhanced security issue analysis
security_critical=0
security_high=0


# Parse pip-audit results
audit_vulns=$(parse_json_int "$REPORTS_DIR/pip-audit.json" ".vulnerabilities | length")
if [ "$audit_vulns" -gt 0 ]; then
    security_high=$((security_high + audit_vulns))
fi

# Classify security findings
if [ "$security_critical" -gt 0 ]; then
    has_errors="true"
    echo "❌ $security_critical critical security issues found"
elif [ "$security_high" -gt 0 ]; then
    has_warnings="true"
    echo "⚠️ $security_high high/medium security issues found"
else
    echo "✅ No significant security issues detected"
fi

# Output results to GitHub Actions
echo "has-errors=$has_errors" >> "$GITHUB_OUTPUT"
echo "has-warnings=$has_warnings" >> "$GITHUB_OUTPUT"

# Output summary for other scripts
echo "HAS_ERRORS=$has_errors" > "$REPORTS_DIR/check-results.env"
echo "HAS_WARNINGS=$has_warnings" >> "$REPORTS_DIR/check-results.env"
echo "SECURITY_CRITICAL=$security_critical" >> "$REPORTS_DIR/check-results.env"
echo "SECURITY_HIGH=$security_high" >> "$REPORTS_DIR/check-results.env"

echo "Results analysis complete"
