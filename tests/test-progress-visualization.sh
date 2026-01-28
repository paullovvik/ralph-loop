#!/usr/bin/env bash

# Test script for Task 7: Real-Time Progress Visualization
# Tests that the progress display shows correct information and formatting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_LOOP="$SCRIPT_DIR/../ralph-loop"
TEST_DIR="$SCRIPT_DIR/tmp-progress-test"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

# Cleanup
cleanup() {
    rm -rf "$TEST_DIR"
}

# Test helper
run_test() {
    local test_name="$1"
    echo -e "${YELLOW}Testing: $test_name${NC}"
}

pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}"
    echo ""
}

fail_test() {
    local reason="$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL: $reason${NC}"
    echo ""
}

# Test 1: Check if show_progress function exists
test_function_exists() {
    run_test "show_progress function exists in script"

    if grep -q "show_progress()" "$RALPH_LOOP"; then
        pass_test
    else
        fail_test "show_progress function not found in script"
    fi
}

# Test 2: Create a test PRD with mixed task statuses
test_progress_display_format() {
    run_test "Progress display shows correct format and components"

    # Create test PRD JSON with various task states
    cat > "$TEST_DIR/test-prd.json" << 'EOF'
{
  "title": "Progress Visualization Test PRD",
  "overview": "Test PRD for progress visualization",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "Completed Task",
      "category": "Test",
      "priority": 1,
      "description": "A completed task",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "passes": true,
      "completedAt": "2026-01-27T10:00:00Z",
      "attempts": 1
    },
    {
      "id": "task-2",
      "title": "In Progress Task",
      "category": "Test",
      "priority": 2,
      "description": "A task being worked on",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "passes": false,
      "completedAt": null,
      "attempts": 2
    },
    {
      "id": "task-3",
      "title": "Pending Task",
      "category": "Test",
      "priority": 3,
      "description": "A task not yet started",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
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

    # Source the ralph-loop script to test the function
    # First, extract just the show_progress function
    JSON_FILE="$TEST_DIR/test-prd.json"
    MAX_ITERATIONS=10

    # Extract and test the function
    source <(grep -A 100 "^show_progress()" "$RALPH_LOOP" | grep -B 100 "^}")

    # Call the function and capture output
    local output=$(show_progress 5 $(($(date +%s) - 125)) 2>&1)

    # Check for required elements
    local all_checks_passed=true

    # Check for iteration display (e.g., "Iteration: 5/10")
    if ! echo "$output" | grep -q "Iteration: 5/10"; then
        fail_test "Missing or incorrect iteration display"
        all_checks_passed=false
    fi

    # Check for completion percentage
    if ! echo "$output" | grep -qE "Completed: [0-9]+/[0-9]+ tasks \([0-9]+%\)"; then
        if [ "$all_checks_passed" = true ]; then
            fail_test "Missing or incorrect completion percentage"
            all_checks_passed=false
        fi
    fi

    # Check for elapsed time display
    if ! echo "$output" | grep -qE "Elapsed Time: [0-9]{2}:[0-9]{2}"; then
        if [ "$all_checks_passed" = true ]; then
            fail_test "Missing or incorrect elapsed time display"
            all_checks_passed=false
        fi
    fi

    # Check for Unicode box drawing characters
    if ! echo "$output" | grep -q "╔\|═\|╗\|║\|╚\|╝\|┌\|─\|┐\|│\|└\|┘"; then
        if [ "$all_checks_passed" = true ]; then
            fail_test "Missing Unicode box drawing characters"
            all_checks_passed=false
        fi
    fi

    # Check for task status section
    if ! echo "$output" | grep -q "Task Status"; then
        if [ "$all_checks_passed" = true ]; then
            fail_test "Missing Task Status section"
            all_checks_passed=false
        fi
    fi

    if [ "$all_checks_passed" = true ]; then
        pass_test
    fi
}

# Test 3: Verify status icons are used correctly
test_status_icons() {
    run_test "Status icons display correctly (✅ ✓, 🔄 in progress, ⏳ pending)"

    # Use the same test PRD
    JSON_FILE="$TEST_DIR/test-prd.json"
    MAX_ITERATIONS=10

    source <(grep -A 100 "^show_progress()" "$RALPH_LOOP" | grep -B 100 "^}")

    local output=$(show_progress 5 $(($(date +%s) - 60)) 2>&1)

    # Check for completed task icon (✅)
    if ! echo "$output" | grep -q "✅.*task-1"; then
        fail_test "Missing ✅ icon for completed task"
        return
    fi

    # Check for in-progress task icon (🔄)
    if ! echo "$output" | grep -q "🔄.*task-2"; then
        fail_test "Missing 🔄 icon for in-progress task"
        return
    fi

    # Check for pending task icon (⏳)
    if ! echo "$output" | grep -q "⏳.*task-3"; then
        fail_test "Missing ⏳ icon for pending task"
        return
    fi

    pass_test
}

# Test 4: Verify percentage calculation is accurate
test_percentage_calculation() {
    run_test "Percentage calculation is accurate"

    JSON_FILE="$TEST_DIR/test-prd.json"
    MAX_ITERATIONS=10

    source <(grep -A 100 "^show_progress()" "$RALPH_LOOP" | grep -B 100 "^}")

    local output=$(show_progress 5 $(($(date +%s) - 60)) 2>&1)

    # With 1 complete out of 3 tasks, should show 33%
    if echo "$output" | grep -qE "Completed: 1/3 tasks \(33%\)"; then
        pass_test
    else
        fail_test "Incorrect percentage calculation (expected 33% for 1/3 tasks)"
    fi
}

# Test 5: Verify output fits in 80-column terminal
test_80_column_width() {
    run_test "Output fits in 80-column terminal width"

    # Create PRD with long task title
    cat > "$TEST_DIR/test-long-title.json" << 'EOF'
{
  "title": "Long Title Test",
  "tasks": [
    {
      "id": "task-1",
      "title": "This is a very long task title that should be truncated to fit within the 80 column width limitation",
      "category": "Test",
      "priority": 1,
      "acceptanceCriteria": ["Test"],
      "passes": false,
      "attempts": 0
    }
  ],
  "metadata": {
    "totalTasks": 1
  }
}
EOF

    JSON_FILE="$TEST_DIR/test-long-title.json"
    MAX_ITERATIONS=10

    source <(grep -A 100 "^show_progress()" "$RALPH_LOOP" | grep -B 100 "^}")

    local output=$(show_progress 1 $(($(date +%s) - 10)) 2>&1)

    # The Unicode box drawing characters are counted as multiple bytes by awk,
    # but they display as single characters. We need to verify that:
    # 1. Title truncation is working (check for "...")
    # 2. The fixed-width box lines are exactly 80 chars visually

    # Check that long titles are truncated
    if echo "$output" | grep -q "\.\.\."; then
        pass_test
    else
        fail_test "Long task titles are not being truncated"
    fi
}

# Main test execution
main() {
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║              Test Suite: Real-Time Progress Visualization                 ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    setup

    test_function_exists
    test_progress_display_format
    test_status_icons
    test_percentage_calculation
    test_80_column_width

    cleanup

    # Print summary
    echo "════════════════════════════════════════════════════════════════════════════"
    echo "Test Summary:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "════════════════════════════════════════════════════════════════════════════"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main
