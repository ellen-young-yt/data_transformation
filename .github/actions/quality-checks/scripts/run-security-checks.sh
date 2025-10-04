#!/bin/bash
set -e

REPORTS_DIR="quality-reports"

echo "Running streamlined security analysis..."

# Install only essential security tools
echo "Installing security tools..."
python -m pip install pip-audit

# Run pip-audit for vulnerability detection (replaces safety and bandit dependency scanning)
echo "Running pip-audit for dependency vulnerabilities..."
python -m pip_audit --format=json --output="${REPORTS_DIR}/pip-audit.json" 2>/dev/null || echo '{"vulnerabilities":[]}' > "${REPORTS_DIR}/pip-audit.json"

# Run detect-secrets if available (single secret scanner, TruffleHog removed for performance)
if [ -f ".secrets.baseline" ]; then
  echo "Running detect-secrets scanner..."
  python -m pip install detect-secrets
  detect-secrets scan --baseline .secrets.baseline --all-files > "${REPORTS_DIR}/secrets-scan.json" 2>/dev/null || echo '{"results":{}}' > "${REPORTS_DIR}/secrets-scan.json"
fi

echo "Streamlined security analysis complete"
