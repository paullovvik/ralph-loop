#!/usr/bin/env bash

# Test suite for PRD analysis feature

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
    echo -e "${YELLOW}INFO:${NC} $1"
}

# Setup test environment
setup() {
    TEST_DIR=$(mktemp -d)
    info "Created test directory: $TEST_DIR"
}

# Cleanup test environment
cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        info "Cleaned up test directory"
    fi
}

# Test 1: Triggered by --analyze-prd flag
test_analyze_flag() {
    echo ""
    echo "Test 1: --analyze-prd flag triggers analysis"

    cat > "$TEST_DIR/analyze-test.json" << 'EOF'
{
  "title": "Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Test Task",
      "category": "Testing",
      "priority": 1,
      "description": "A test task",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/analyze-test.json" --analyze-prd > "$TEST_DIR/analyze-output.txt" 2>&1 || true

    if grep -qi "analy" "$TEST_DIR/analyze-output.txt"; then
        pass "--analyze-prd flag triggers analysis"
    else
        fail "--analyze-prd flag does not trigger analysis"
    fi
}

# Test 2: Runs validation checks first
test_validation_first() {
    echo ""
    echo "Test 2: Runs validation before analysis"

    cat > "$TEST_DIR/invalid-for-analysis.json" << 'EOF'
{
  "title": "Invalid PRD",
  "tasks": []
}
EOF

    ../ralph-loop "$TEST_DIR/invalid-for-analysis.json" --analyze-prd > "$TEST_DIR/validation-first.txt" 2>&1 || true

    if grep -qi "validation\|error\|invalid" "$TEST_DIR/validation-first.txt"; then
        pass "Validation runs before analysis"
    else
        fail "Validation does not run before analysis"
    fi
}

# Test 3: Shows statistics (task count, categories, criteria distribution)
test_statistics() {
    echo ""
    echo "Test 3: Shows PRD statistics"

    cat > "$TEST_DIR/stats-test.json" << 'EOF'
{
  "title": "Statistics Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "First Task",
      "category": "Backend",
      "priority": 1,
      "description": "Backend work",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2", "Criterion 3"],
      "passes": false
    },
    {
      "id": "task-2",
      "title": "Second Task",
      "category": "Frontend",
      "priority": 2,
      "description": "Frontend work",
      "acceptanceCriteria": ["Criterion 1"],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/stats-test.json" --analyze-prd > "$TEST_DIR/stats-output.txt" 2>&1 || true

    local has_stats=0

    if grep -qi "task.*count\|total.*task\|[0-9].*task" "$TEST_DIR/stats-output.txt"; then
        has_stats=$((has_stats + 1))
    fi

    if grep -qi "categor" "$TEST_DIR/stats-output.txt"; then
        has_stats=$((has_stats + 1))
    fi

    if [ "$has_stats" -ge 1 ]; then
        pass "Analysis shows PRD statistics"
    else
        fail "Analysis missing statistics"
    fi
}

# Test 4: Provides task-by-task feedback
test_task_feedback() {
    echo ""
    echo "Test 4: Provides task-by-task feedback"

    cat > "$TEST_DIR/feedback-test.json" << 'EOF'
{
  "title": "Feedback Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Well-defined task",
      "category": "Testing",
      "priority": 1,
      "description": "This task has clear, specific acceptance criteria with test commands.",
      "acceptanceCriteria": [
        "Test: Run npm test and verify all tests pass",
        "Test: Run npm run lint and verify no errors",
        "Verify code coverage is above 80%"
      ],
      "passes": false
    },
    {
      "id": "task-2",
      "title": "Vague task",
      "category": "Testing",
      "priority": 2,
      "description": "This task is vague",
      "acceptanceCriteria": [
        "Make it work",
        "Looks good"
      ],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/feedback-test.json" --analyze-prd > "$TEST_DIR/feedback-output.txt" 2>&1 || true

    if grep -qi "task-1\|task-2\|first task\|second task" "$TEST_DIR/feedback-output.txt"; then
        pass "Analysis provides per-task feedback"
    else
        fail "Analysis missing per-task feedback"
    fi
}

# Test 5: Exits after analysis without starting loop
test_exits_after_analysis() {
    echo ""
    echo "Test 5: Exits after analysis without starting loop"

    cat > "$TEST_DIR/exit-test.json" << 'EOF'
{
  "title": "Exit Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Test Task",
      "category": "Testing",
      "priority": 1,
      "description": "Test",
      "acceptanceCriteria": ["Test criterion"],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/exit-test.json" --analyze-prd > "$TEST_DIR/exit-output.txt" 2>&1 || true

    # Should not contain iteration-related output
    if ! grep -qi "iteration.*1\|starting.*loop\|calling.*claude" "$TEST_DIR/exit-output.txt"; then
        pass "Analysis exits without starting loop"
    else
        fail "Analysis started the loop instead of exiting"
    fi

    # Should not create progress.txt
    if [ ! -f "$TEST_DIR/progress.txt" ]; then
        pass "No progress file created during analysis"
    else
        fail "Progress file created during analysis"
    fi
}

# Test 6: Suggests improvements for vague criteria
test_improvement_suggestions() {
    echo ""
    echo "Test 6: Suggests improvements for vague PRD"

    cat > "$TEST_DIR/vague-test.json" << 'EOF'
{
  "title": "Vague PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Do something",
      "category": "General",
      "priority": 1,
      "description": "Make it work",
      "acceptanceCriteria": [
        "It works",
        "Looks good",
        "User likes it"
      ],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/vague-test.json" --analyze-prd > "$TEST_DIR/vague-output.txt" 2>&1 || true

    if grep -qi "vague\|specific\|improve\|suggest\|clarif\|more detail" "$TEST_DIR/vague-output.txt"; then
        pass "Analysis suggests improvements for vague criteria"
    else
        fail "Analysis does not suggest improvements"
    fi
}

# Test 7: Shows overall recommendations at the end
test_overall_recommendations() {
    echo ""
    echo "Test 7: Shows overall recommendations"

    cat > "$TEST_DIR/recommendations-test.json" << 'EOF'
{
  "title": "Recommendations Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Task One",
      "category": "Testing",
      "priority": 1,
      "description": "First task",
      "acceptanceCriteria": ["Criterion 1"],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/recommendations-test.json" --analyze-prd > "$TEST_DIR/recommendations-output.txt" 2>&1 || true

    if grep -qi "recommend\|overall\|summar\|conclusion" "$TEST_DIR/recommendations-output.txt"; then
        pass "Analysis includes overall recommendations"
    else
        fail "Analysis missing overall recommendations"
    fi
}

# Test 8: Works with well-written PRD
test_well_written_prd() {
    echo ""
    echo "Test 8: Analyzes well-written PRD"

    cat > "$TEST_DIR/good-prd.json" << 'EOF'
{
  "title": "Well-Written PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Implement user authentication",
      "category": "Backend",
      "priority": 1,
      "description": "Add JWT-based authentication to the API endpoints",
      "acceptanceCriteria": [
        "Test: POST /api/auth/login with valid credentials returns JWT token",
        "Test: Protected endpoints reject requests without valid JWT",
        "Test: JWT tokens expire after 24 hours",
        "Error handling: Invalid credentials return 401 with clear message",
        "Security: Passwords are hashed with bcrypt before storage"
      ],
      "passes": false
    }
  ]
}
EOF

    ../ralph-loop "$TEST_DIR/good-prd.json" --analyze-prd > "$TEST_DIR/good-output.txt" 2>&1 || true

    if [ -s "$TEST_DIR/good-output.txt" ]; then
        pass "Analysis works with well-written PRD"
    else
        fail "Analysis failed with well-written PRD"
    fi
}

# Test 9: Handles markdown conversion before analysis
test_markdown_analysis() {
    echo ""
    echo "Test 9: Analyzes markdown PRD file"

    cat > "$TEST_DIR/markdown-test.md" << 'EOF'
## Task: Test Task
**Category**: Testing
**Priority**: 1

Description here.

### Acceptance Criteria
- First criterion
- Second criterion
EOF

    ../ralph-loop "$TEST_DIR/markdown-test.md" --analyze-prd > "$TEST_DIR/markdown-analysis.txt" 2>&1 || true

    if grep -qi "analy" "$TEST_DIR/markdown-analysis.txt"; then
        pass "Analysis works with markdown files"
    else
        fail "Analysis failed with markdown file"
    fi

    # Should have created JSON file
    if [ -f "$TEST_DIR/markdown-test.json" ]; then
        pass "Markdown converted to JSON before analysis"
    else
        fail "Markdown not converted to JSON"
    fi
}

# Main test execution
main() {
    echo "========================================"
    echo "PRD Analysis Test Suite"
    echo "========================================"

    setup

    test_analyze_flag
    test_validation_first
    test_statistics
    test_task_feedback
    test_exits_after_analysis
    test_improvement_suggestions
    test_overall_recommendations
    test_well_written_prd
    test_markdown_analysis

    cleanup

    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo "========================================"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
