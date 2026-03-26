#!/bin/bash
# Stop hook: Run PHPUnit tests and Mago static analysis.
set -uo pipefail

cd "$CLAUDE_PROJECT_DIR"

echo "=== PHPUnit ==="
vendor/bin/phpunit 2>&1 | tail -30

echo ""
echo "=== Mago Lint ==="
vendor/bin/mago lint 2>&1 | tail -30

echo ""
echo "=== Mago Analyze ==="
vendor/bin/mago analyze 2>&1 | tail -30

exit 0
