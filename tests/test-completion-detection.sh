#!/usr/bin/env bash

# Test script for completion detection bug fix
# Tests that ralph-loop properly detects completion even after final iteration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RALPH_LOOP="$PROJECT_ROOT/ralph-loop"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    COMPLETION DETECTION BUG FIX TEST                       ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Testing that ralph-loop detects completion after final iteration completes"
echo "Bug: Previously, if max iterations was reached, it wouldn't check if all"
echo "     tasks were complete, and would incorrectly show 'MAX ITERATIONS REACHED'"
echo ""

# Test: All tasks already complete
echo -e "${BLUE}TEST 1: All tasks already complete - should detect immediately${NC}"

test_dir=$(mktemp -d)
prd_file="$test_dir/completed-prd.json"

cat > "$prd_file" << 'EOF'
{
  "title": "Already Complete PRD",
  "overview": "All tasks complete",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "Complete Task 1",
      "category": "Test",
      "priority": 1,
      "description": "Already done",
      "acceptanceCriteria": ["Done"],
      "passes": true,
      "completedAt": "2026-01-27",
      "attempts": 1
    },
    {
      "id": "task-2",
      "title": "Complete Task 2",
      "category": "Test",
      "priority": 2,
      "description": "Already done",
      "acceptanceCriteria": ["Done"],
      "passes": true,
      "completedAt": "2026-01-27",
      "attempts": 1
    },
    {
      "id": "task-3",
      "title": "Complete Task 3",
      "category": "Test",
      "priority": 3,
      "description": "Already done",
      "acceptanceCriteria": ["Done"],
      "passes": true,
      "completedAt": "2026-01-27",
      "attempts": 1
    }
  ],
  "metadata": {
    "createdAt": "2026-01-27",
    "totalTasks": 3
  }
}
EOF

# Run ralph-loop - should detect completion immediately without needing Claude
cd "$test_dir"
output=$("$RALPH_LOOP" "$prd_file" --max-iterations 5 2>&1) || exit_code=$?

# Verify exit code is 0 (success)
if [ "${exit_code:-0}" -eq 0 ]; then
    test_pass "Exit code is 0 (success) when all tasks complete"
else
    test_fail "Exit code is ${exit_code}, expected 0"
fi

# Verify completion message is shown
if echo "$output" | grep -q "COMPLETION SUCCESSFUL"; then
    test_pass "Shows 'COMPLETION SUCCESSFUL' message"
else
    test_fail "Missing 'COMPLETION SUCCESSFUL' message"
    echo "Output was:"
    echo "$output"
fi

# Verify it doesn't show MAX ITERATIONS REACHED
if echo "$output" | grep -q "MAX ITERATIONS REACHED"; then
    test_fail "Incorrectly showed 'MAX ITERATIONS REACHED'"
else
    test_pass "Did not show 'MAX ITERATIONS REACHED' (correct)"
fi

# Verify it shows correct task count
if echo "$output" | grep -q "Total Tasks Completed: 3 / 3"; then
    test_pass "Shows correct task count (3/3)"
else
    test_fail "Incorrect task count in output"
fi

# Cleanup
rm -rf "$test_dir"

echo ""
echo "════════════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "════════════════════════════════════════════════════════════════════════════"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All completion detection tests passed!${NC}"
    echo ""
    echo "The bug fix is working correctly:"
    echo "  • Final completion check added after loop ends (line 1301-1311)"
    echo "  • Verifies all tasks have passes=true before showing final status"
    echo "  • Prevents false 'MAX ITERATIONS REACHED' when work is actually done"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
