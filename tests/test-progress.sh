#!/usr/bin/env bash

# Test script for Progress File Management (Task 6)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RALPH_LOOP="$PROJECT_ROOT/ralph-loop"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    echo -e "${BLUE}TEST: $1${NC}"
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Setup: Create a test PRD
setup_test_prd() {
    local test_dir="$1"
    local prd_file="$test_dir/test-prd.json"

    cat > "$prd_file" << 'EOF'
{
  "title": "Test PRD for Progress Management",
  "overview": "Simple test PRD",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "Test Task 1",
      "category": "Testing",
      "priority": 1,
      "description": "First test task",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    },
    {
      "id": "task-2",
      "title": "Test Task 2",
      "category": "Testing",
      "priority": 2,
      "description": "Second test task",
      "acceptanceCriteria": [
        "Criterion A",
        "Criterion B"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    }
  ],
  "metadata": {
    "createdAt": "2026-01-27",
    "totalTasks": 2
  }
}
EOF
    echo "$prd_file"
}

# Test 1: Progress file is created
test_progress_file_created() {
    test_start "Progress file is created when it doesn't exist"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Run ralph-loop (it will stop early but should create progress.txt)
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" --max-iterations 1 > /dev/null 2>&1 || true

    if [ -f "$progress_file" ]; then
        test_pass "Progress file created at $progress_file"
    else
        test_fail "Progress file was not created"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 2: Progress file has correct header
test_progress_file_header() {
    test_start "Progress file has correct header with start time, PRD path, and max iterations"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Run ralph-loop
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" --max-iterations 5 > /dev/null 2>&1 || true

    if [ ! -f "$progress_file" ]; then
        test_fail "Progress file not created"
        rm -rf "$test_dir"
        return
    fi

    local has_start_time=$(grep -c "Start Time:" "$progress_file" || echo 0)
    local has_prd_path=$(grep -c "PRD Path:" "$progress_file" || echo 0)
    local has_max_iterations=$(grep -c "Max Iterations: 5" "$progress_file" || echo 0)

    if [ "$has_start_time" -gt 0 ] && [ "$has_prd_path" -gt 0 ] && [ "$has_max_iterations" -gt 0 ]; then
        test_pass "Progress file contains header with start time, PRD path, and max iterations"
    else
        test_fail "Progress file missing required header information"
        echo "  has_start_time=$has_start_time, has_prd_path=$has_prd_path, has_max_iterations=$has_max_iterations"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 3: Progress file is human-readable
test_progress_file_format() {
    test_start "Progress file format is human-readable with section separators"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Run ralph-loop
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" > /dev/null 2>&1 || true

    if [ ! -f "$progress_file" ]; then
        test_fail "Progress file not created"
        rm -rf "$test_dir"
        return
    fi

    # Check for Unicode box drawing characters
    local has_box_chars=$(grep -c "╔\|═\|╚\|┌\|─\|└" "$progress_file" || echo 0)

    if [ "$has_box_chars" -gt 0 ]; then
        test_pass "Progress file has readable format with section separators"
    else
        test_fail "Progress file missing visual section separators"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 4: Existing progress file is archived
test_progress_file_archived() {
    test_start "Existing progress file is archived with timestamp when starting fresh"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Create an existing progress file
    echo "Old progress data" > "$progress_file"

    # Run ralph-loop (should archive the old file)
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" > /dev/null 2>&1 || true

    # Check if archive file was created
    local archive_count=$(ls "$test_dir"/progress-*.txt 2>/dev/null | wc -l)

    if [ "$archive_count" -gt 0 ]; then
        test_pass "Existing progress file was archived"

        # Verify old content is in archive
        local archive_file=$(ls "$test_dir"/progress-*.txt | head -1)
        local has_old_content=$(grep -c "Old progress data" "$archive_file" || echo 0)

        if [ "$has_old_content" -gt 0 ]; then
            test_pass "Archived file contains old progress data"
        else
            test_fail "Archived file doesn't contain old progress data"
        fi
    else
        test_fail "Existing progress file was not archived"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 5: Progress file is appended when resuming
test_progress_file_append() {
    test_start "Progress file is appended (not overwritten) when resuming"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Create initial progress file
    cat > "$progress_file" << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                         RALPH LOOP PROGRESS LOG                            ║
╚════════════════════════════════════════════════════════════════════════════╝

Start Time: 2026-01-27 10:00:00
PRD Path: /tmp/test.json
Max Iterations: 5

════════════════════════════════════════════════════════════════════════════

Original content
EOF

    # Run ralph-loop with --resume
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" --resume > /dev/null 2>&1 || true

    # Check that original content is still there
    local has_original=$(grep -c "Original content" "$progress_file" || echo 0)
    local has_resumed=$(grep -c "RESUMED SESSION" "$progress_file" || echo 0)

    if [ "$has_original" -gt 0 ] && [ "$has_resumed" -gt 0 ]; then
        test_pass "Progress file was appended with resume marker, original content preserved"
    else
        test_fail "Progress file was not properly appended (has_original=$has_original, has_resumed=$has_resumed)"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 6: Progress file not archived when resuming
test_progress_no_archive_on_resume() {
    test_start "Existing progress file is NOT archived when using --resume"

    local test_dir=$(mktemp -d)
    local prd_file=$(setup_test_prd "$test_dir")
    local progress_file="$test_dir/progress.txt"

    # Create an existing progress file
    echo "Existing progress" > "$progress_file"

    # Run ralph-loop with --resume
    cd "$test_dir"
    "$RALPH_LOOP" "$prd_file" --resume > /dev/null 2>&1 || true

    # Check that no archive file was created
    local archive_count=$(ls "$test_dir"/progress-*.txt 2>/dev/null | wc -l)

    if [ "$archive_count" -eq 0 ]; then
        test_pass "No archive file created when using --resume"
    else
        test_fail "Archive file was created when it shouldn't have been (found $archive_count)"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Run all tests
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                   PROGRESS FILE MANAGEMENT TESTS                           ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

test_progress_file_created
echo ""

test_progress_file_header
echo ""

test_progress_file_format
echo ""

test_progress_file_archived
echo ""

test_progress_file_append
echo ""

test_progress_no_archive_on_resume
echo ""

# Test 7: Completion detection after final iteration
test_completion_detection_final_check() {
    test_start "Final completion check detects when all tasks are complete"

    local test_dir=$(mktemp -d)
    local prd_file="$test_dir/test-completion-prd.json"
    local progress_file="$test_dir/progress.txt"

    # Create a PRD where all tasks are already complete
    cat > "$prd_file" << 'EOF'
{
  "title": "Test PRD - All Complete",
  "overview": "PRD with all tasks complete",
  "projectDirectory": "/tmp",
  "tasks": [
    {
      "id": "task-1",
      "title": "Complete Task 1",
      "category": "Testing",
      "priority": 1,
      "description": "Already completed",
      "acceptanceCriteria": ["Done"],
      "passes": true,
      "completedAt": "2026-01-27",
      "attempts": 1
    },
    {
      "id": "task-2",
      "title": "Complete Task 2",
      "category": "Testing",
      "priority": 2,
      "description": "Already completed",
      "acceptanceCriteria": ["Done"],
      "passes": true,
      "completedAt": "2026-01-27",
      "attempts": 1
    }
  ],
  "metadata": {
    "createdAt": "2026-01-27",
    "totalTasks": 2
  }
}
EOF

    # Run ralph-loop - should detect completion immediately
    cd "$test_dir"
    local output=$("$RALPH_LOOP" "$prd_file" --max-iterations 3 2>&1)
    local exit_code=$?

    # Check that it detected completion and exited with success
    if [ $exit_code -eq 0 ]; then
        test_pass "Exit code is 0 (success) when all tasks complete"
    else
        test_fail "Exit code is $exit_code, expected 0"
    fi

    # Check that completion message is shown
    if echo "$output" | grep -q "COMPLETION SUCCESSFUL\|All tasks completed"; then
        test_pass "Completion success message displayed"
    else
        test_fail "Missing completion success message"
    fi

    # Check that it doesn't show "MAX ITERATIONS REACHED"
    if echo "$output" | grep -q "MAX ITERATIONS REACHED"; then
        test_fail "Incorrectly showed MAX ITERATIONS REACHED for completed tasks"
    else
        test_pass "Did not show MAX ITERATIONS REACHED message"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

test_completion_detection_final_check
echo ""

# Summary
echo "════════════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "════════════════════════════════════════════════════════════════════════════"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
