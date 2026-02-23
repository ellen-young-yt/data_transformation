#!/bin/bash
# Run SQLFluff with dbt templater for comprehensive SQL validation
# This runs in CI only, after dbt dependencies have been installed

set +e  # Don't exit on error, we want to capture results

REPORTS_DIR="quality-reports"

echo "Running SQLFluff with dbt templater for comprehensive validation..."

# Find sqlfluff executable (CI vs local development)
SQLFLUFF_CMD="sqlfluff"
if [ ! -x "$(command -v sqlfluff)" ]; then
  # Try virtual environment
  if [ -f "transform/Scripts/sqlfluff.exe" ]; then
    SQLFLUFF_CMD="./transform/Scripts/sqlfluff.exe"
  elif [ -f "transform/bin/sqlfluff" ]; then
    SQLFLUFF_CMD="./transform/bin/sqlfluff"
  fi
fi

# Use the dbt-specific sqlfluff config
$SQLFLUFF_CMD lint \
  --config .sqlfluff.dbt \
  models/ \
  > "$REPORTS_DIR/sqlfluff-dbt-report.txt" 2>&1

sqlfluff_dbt_exit=$?

# Show summary
if [ "$sqlfluff_dbt_exit" -eq "0" ]; then
  echo "✅ SQLFluff dbt templater validation passed"
else
  echo "⚠️ SQLFluff dbt templater found issues"
  echo "See quality-reports/sqlfluff-dbt-report.txt for details"

  # Show summary of issues if available
  if [ -f "$REPORTS_DIR/sqlfluff-dbt-report.txt" ]; then
    echo ""
    echo "Issue summary:"
    grep -E "^(==|L:)" "$REPORTS_DIR/sqlfluff-dbt-report.txt" | head -20 || true
  fi
fi

# Output for GitHub Actions (only if in GitHub Actions environment)
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "exit_code=$sqlfluff_dbt_exit" >> "$GITHUB_OUTPUT"
fi

exit "$sqlfluff_dbt_exit"
