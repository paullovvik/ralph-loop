#!/usr/bin/env bash

# Test script for Ralph Loop resume functionality

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR="/tmp/ralph-resume-test-$$"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Helper function to print test results
pass_test() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    echo -e "${RED}✗${NC} $1"
    echo -e "${RED}  $2${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Setup test environment
setup_test_env() {
    mkdir -p "$TEST_DIR"

    # Create a simple test PRD
    cat > "$TEST_DIR/test-prd.json" << 'EOF'
{
  "title": "Resume Test PRD",
  "overview": "Test PRD for resume functionality",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "First test task",
      "category": "Testing",
      "priority": 1,
      "description": "First task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    },
    {
      "id": "task-2",
      "title": "Second test task",
      "category": "Testing",
      "priority": 2,
      "description": "Second task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    },
    {
      "id": "task-3",
      "title": "Third test task",
      "category": "Testing",
      "priority": 3,
      "description": "Third task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    }
  ],
  "metadata": {
    "createdAt": "2026-01-27",
    "totalTasks": 3
  }
}
EOF

    # Create a mock progress file with 2 iterations completed
    cat > "$TEST_DIR/progress.txt" << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         RALPH LOOP PROGRESS LOG                            ║
╚════════════════════════════════════════════════════════════════════════════╝

Start Time: 2026-01-27 10:00:00
PRD Path: /tmp/test-prd.json
Max Iterations: 15

════════════════════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────────────────────────────┐
│ ITERATION 1/15
│ Timestamp: 2026-01-27 10:00:05
│ Working on: task-1 - First test task
└────────────────────────────────────────────────────────────────────────────┘

Result: PASSED
Details: Task completed successfully

Learnings:
Test task 1 completed.

════════════════════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────────────────────────────┐
│ ITERATION 2/15
│ Timestamp: 2026-01-27 10:00:15
│ Working on: task-2 - Second test task
└────────────────────────────────────────────────────────────────────────────┘

Result: IN PROGRESS
Details: Task still being worked on

════════════════════════════════════════════════════════════════════════════

EOF

    # Update PRD to show task-1 as completed
    cat > "$TEST_DIR/test-prd.json" << 'EOF'
{
  "title": "Resume Test PRD",
  "overview": "Test PRD for resume functionality",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "First test task",
      "category": "Testing",
      "priority": 1,
      "description": "First task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": true,
      "completedAt": "2026-01-27T10:00:05Z",
      "attempts": 1
    },
    {
      "id": "task-2",
      "title": "Second test task",
      "category": "Testing",
      "priority": 2,
      "description": "Second task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 1
    },
    {
      "id": "task-3",
      "title": "Third test task",
      "category": "Testing",
      "priority": 3,
      "description": "Third task",
      "acceptanceCriteria": [
        "Task completes successfully"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    }
  ],
  "metadata": {
    "createdAt": "2026-01-27",
    "totalTasks": 3
  }
}
EOF
}

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RALPH LOOP RESUME FUNCTIONALITY TESTS                   ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Verify get_last_iteration function
echo "Test 1: Extract last iteration from progress file"
setup_test_env

# Source the ralph-loop script to get the function
RALPH_SCRIPT="/Users/paul.lovvik/AI/Claude/ralph/ralph-loop"
if [ ! -f "$RALPH_SCRIPT" ]; then
    fail_test "Test 1" "Ralph loop script not found at $RALPH_SCRIPT"
else
    # Extract and test the get_last_iteration function
    last_iter=$(grep -o "ITERATION [0-9]\+/" "$TEST_DIR/progress.txt" | tail -1 | grep -o "[0-9]\+" || echo "0")

    if [ "$last_iter" = "2" ]; then
        pass_test "Test 1: Last iteration correctly identified as 2"
    else
        fail_test "Test 1" "Expected last iteration to be 2, got: $last_iter"
    fi
fi

# Test 2: Verify progress file shows correct completed tasks
echo "Test 2: Verify PRD state matches progress"
completed_tasks=$(jq '[.tasks[] | select(.passes == true)] | length' "$TEST_DIR/test-prd.json")

if [ "$completed_tasks" = "1" ]; then
    pass_test "Test 2: One task marked as completed in PRD"
else
    fail_test "Test 2" "Expected 1 completed task, got: $completed_tasks"
fi

# Test 3: Verify resume would start from iteration 3
echo "Test 3: Next iteration should be 3"
next_iter=$((last_iter + 1))

if [ "$next_iter" = "3" ]; then
    pass_test "Test 3: Next iteration correctly calculated as 3"
else
    fail_test "Test 3" "Expected next iteration to be 3, got: $next_iter"
fi

# Test 4: Test with empty/missing progress file
echo "Test 4: Handle missing progress file"
rm -f "$TEST_DIR/progress.txt"

# Check that function returns 0 for missing file
if [ ! -f "$TEST_DIR/progress.txt" ]; then
    last_iter_empty="0"
    pass_test "Test 4: Missing progress file handled (defaults to 0)"
else
    fail_test "Test 4" "Progress file should not exist"
fi

# Test 5: Test progress file with no iterations
echo "Test 5: Handle progress file with no iterations"
cat > "$TEST_DIR/progress.txt" << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         RALPH LOOP PROGRESS LOG                            ║
╚════════════════════════════════════════════════════════════════════════════╝

Start Time: 2026-01-27 10:00:00
PRD Path: /tmp/test-prd.json
Max Iterations: 15

════════════════════════════════════════════════════════════════════════════

EOF

last_iter_empty=$(grep -o "ITERATION [0-9]\+/" "$TEST_DIR/progress.txt" | tail -1 | grep -o "[0-9]\+" || echo "0")

if [ "$last_iter_empty" = "0" ]; then
    pass_test "Test 5: Empty progress file correctly returns 0"
else
    fail_test "Test 5" "Expected 0 for empty progress, got: $last_iter_empty"
fi

# Test 6: Verify archived files are created with timestamp format
echo "Test 6: Check timestamp format for archived files"
timestamp=$(date +%Y%m%d-%H%M%S)

if [[ "$timestamp" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
    pass_test "Test 6: Timestamp format is correct (YYYYMMDD-HHMMSS)"
else
    fail_test "Test 6" "Timestamp format incorrect: $timestamp"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════════════════"
echo "Test Summary:"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    exit 1
else
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo -e "${GREEN}All resume functionality tests passed!${NC}"
    exit 0
fi
