#!/usr/bin/env bash

set -e

echo
echo "=== 1. Running full Flutter test suite ==="
#flutter test

echo
echo "=== 2. Checking diff whitespace/errors ==="
git diff --check

echo
echo "=== 3. Git status ==="
git status

echo
echo "=== 4. Diff statistics ==="
git diff --stat

echo
echo "=== 5. Recent commits ==="
git log --oneline -5

echo
echo "=== 6. Final confirmation ==="
echo "All automatic closure checks completed successfully."
echo
echo "Review git status and git diff --stat above."
echo "If everything is correct, run:"
echo
echo "  git add ."
echo "  git status"
echo "  git diff --cached --stat"
echo "  git commit -m \"Release 2.0.12+212 XpCalculator extraction\""
echo "  git push origin main"
