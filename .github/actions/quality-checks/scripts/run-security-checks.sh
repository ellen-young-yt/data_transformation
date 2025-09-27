#!/bin/bash
set -e

REPORTS_DIR="quality-reports"

echo "Running comprehensive security analysis..."

# Install security tools if not available
echo "Installing security tools..."
python -m pip install bandit safety pip-audit

# Run bandit security check with multiple formats
echo "Running Bandit security scanner..."
python -m bandit -r scripts/ -f json -o "${REPORTS_DIR}/security-report.json" -ll || true
python -m bandit -r scripts/ -f txt -o "${REPORTS_DIR}/security-report.txt" || true

# Run safety check for known vulnerabilities
echo "Running Safety vulnerability scanner..."
python -m safety check --output json > "${REPORTS_DIR}/safety-report.json" || true
python -m safety check --output text > "${REPORTS_DIR}/safety-report.txt" || true

# Run pip-audit for additional vulnerability detection
echo "Running pip-audit..."
python -m pip install pip-audit
python -m pip_audit --format=json --output="${REPORTS_DIR}/pip-audit.json" || true

# Run detect-secrets if available
if [ -f ".secrets.baseline" ]; then
  echo "Running detect-secrets scanner..."
  python -m pip install detect-secrets
  detect-secrets scan --baseline .secrets.baseline --all-files > "${REPORTS_DIR}/secrets-scan.json" || true
fi

echo "Security analysis complete"
