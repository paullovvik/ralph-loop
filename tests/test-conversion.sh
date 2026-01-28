#!/usr/bin/env bash

# Test suite for markdown to JSON conversion

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

# Test 1: Detects if input file is .md or .json
test_file_type_detection() {
    echo ""
    echo "Test 1: File type detection"

    # Create test markdown file
    cat > "$TEST_DIR/test.md" << 'EOF'
## Task: Test Task
**Category**: Testing
**Priority**: 1

### Acceptance Criteria
- Criterion 1
EOF

    # Run with markdown file
    ../ralph-loop "$TEST_DIR/test.md" > "$TEST_DIR/output1.txt" 2>&1 || true

    if [ -f "$TEST_DIR/test.json" ]; then
        pass "Markdown file detected and converted to JSON"
    else
        fail "Markdown file was not converted to JSON"
    fi

    # Run with JSON file - should not create another file
    json_mtime_before=$(stat -f %m "$TEST_DIR/test.json" 2>/dev/null || echo "0")
    sleep 1
    ../ralph-loop "$TEST_DIR/test.json" --verbose > "$TEST_DIR/output2.txt" 2>&1 || true
    json_mtime_after=$(stat -f %m "$TEST_DIR/test.json" 2>/dev/null || echo "0")

    if grep -q "Input is already JSON format" "$TEST_DIR/output2.txt" || \
       [ "$json_mtime_before" = "$json_mtime_after" ]; then
        pass "JSON file detected correctly"
    else
        fail "JSON file not detected correctly"
    fi
}

# Test 2: Parses markdown sections correctly
test_markdown_parsing() {
    echo ""
    echo "Test 2: Markdown parsing"

    cat > "$TEST_DIR/parse-test.md" << 'EOF'
## Task: First Task
**Category**: Backend
**Priority**: 1

Description text here.

### Acceptance Criteria
- First criterion
- Second criterion

## Task: Second Task
**Category**: Frontend
**Priority**: 2

### Acceptance Criteria
- Another criterion
EOF

    ../ralph-loop "$TEST_DIR/parse-test.md" > /dev/null 2>&1 || true

    if [ -f "$TEST_DIR/parse-test.json" ]; then
        # Check if JSON has 2 tasks
        task_count=$(grep -o '"id": "task-' "$TEST_DIR/parse-test.json" | wc -l | tr -d ' ')
        if [ "$task_count" -eq 2 ]; then
            pass "Parsed correct number of tasks (2)"
        else
            fail "Expected 2 tasks, found $task_count"
        fi

        # Check if categories are extracted
        if grep -q '"category": "Backend"' "$TEST_DIR/parse-test.json" && \
           grep -q '"category": "Frontend"' "$TEST_DIR/parse-test.json"; then
            pass "Categories extracted correctly"
        else
            fail "Categories not extracted correctly"
        fi

        # Check if priorities are extracted
        if grep -q '"priority": 1' "$TEST_DIR/parse-test.json" && \
           grep -q '"priority": 2' "$TEST_DIR/parse-test.json"; then
            pass "Priorities extracted correctly"
        else
            fail "Priorities not extracted correctly"
        fi

        # Check if acceptance criteria are parsed
        if grep -q '"First criterion"' "$TEST_DIR/parse-test.json" && \
           grep -q '"Second criterion"' "$TEST_DIR/parse-test.json" && \
           grep -q '"Another criterion"' "$TEST_DIR/parse-test.json"; then
            pass "Acceptance criteria parsed correctly"
        else
            fail "Acceptance criteria not parsed correctly"
        fi
    else
        fail "JSON file not created"
    fi
}

# Test 3: Generates unique task IDs
test_task_ids() {
    echo ""
    echo "Test 3: Task ID generation"

    cat > "$TEST_DIR/ids-test.md" << 'EOF'
## Task: Task One
**Priority**: 1

### Acceptance Criteria
- Criterion

## Task: Task Two
**Priority**: 2

### Acceptance Criteria
- Criterion

## Task: Task Three
**Priority**: 3

### Acceptance Criteria
- Criterion
EOF

    ../ralph-loop "$TEST_DIR/ids-test.md" > /dev/null 2>&1 || true

    if [ -f "$TEST_DIR/ids-test.json" ]; then
        if grep -q '"id": "task-1"' "$TEST_DIR/ids-test.json" && \
           grep -q '"id": "task-2"' "$TEST_DIR/ids-test.json" && \
           grep -q '"id": "task-3"' "$TEST_DIR/ids-test.json"; then
            pass "Unique task IDs generated (task-1, task-2, task-3)"
        else
            fail "Task IDs not generated correctly"
        fi
    else
        fail "JSON file not created"
    fi
}

# Test 4: Initializes task fields correctly
test_task_initialization() {
    echo ""
    echo "Test 4: Task field initialization"

    cat > "$TEST_DIR/init-test.md" << 'EOF'
## Task: Test Task
**Category**: Test
**Priority**: 1

### Acceptance Criteria
- Criterion
EOF

    ../ralph-loop "$TEST_DIR/init-test.md" > /dev/null 2>&1 || true

    if [ -f "$TEST_DIR/init-test.json" ]; then
        if grep -q '"passes": false' "$TEST_DIR/init-test.json"; then
            pass "passes field initialized to false"
        else
            fail "passes field not initialized correctly"
        fi

        if grep -q '"attempts": 0' "$TEST_DIR/init-test.json"; then
            pass "attempts field initialized to 0"
        else
            fail "attempts field not initialized correctly"
        fi

        if grep -q '"completedAt": null' "$TEST_DIR/init-test.json"; then
            pass "completedAt field initialized to null"
        else
            fail "completedAt field not initialized correctly"
        fi
    else
        fail "JSON file not created"
    fi
}

# Test 5: Preserves original markdown file
test_preserve_markdown() {
    echo ""
    echo "Test 5: Preserve original markdown"

    cat > "$TEST_DIR/preserve-test.md" << 'EOF'
## Task: Test
**Priority**: 1

### Acceptance Criteria
- Test
EOF

    cp "$TEST_DIR/preserve-test.md" "$TEST_DIR/preserve-test-backup.md"

    ../ralph-loop "$TEST_DIR/preserve-test.md" > /dev/null 2>&1 || true

    if diff -q "$TEST_DIR/preserve-test.md" "$TEST_DIR/preserve-test-backup.md" > /dev/null; then
        pass "Original markdown file preserved unchanged"
    else
        fail "Original markdown file was modified"
    fi
}

# Test 6: Uses existing JSON instead of reconverting
test_use_existing_json() {
    echo ""
    echo "Test 6: Use existing JSON"

    cat > "$TEST_DIR/existing-test.md" << 'EOF'
## Task: Test
**Priority**: 1

### Acceptance Criteria
- Test
EOF

    # First conversion
    ../ralph-loop "$TEST_DIR/existing-test.md" > /dev/null 2>&1 || true

    # Modify the JSON
    if [ -f "$TEST_DIR/existing-test.json" ]; then
        # Add a marker to the JSON
        sed -i.bak 's/"Converted PRD"/"Modified JSON"/' "$TEST_DIR/existing-test.json"

        # Run again
        ../ralph-loop "$TEST_DIR/existing-test.md" > /dev/null 2>&1 || true

        # Check if the modification is still there
        if grep -q '"Modified JSON"' "$TEST_DIR/existing-test.json"; then
            pass "Existing JSON used instead of reconverting"
        else
            fail "Existing JSON was overwritten"
        fi
    else
        fail "JSON file not created in first run"
    fi
}

# Test 7: Verify all required fields in converted JSON
test_required_fields() {
    echo ""
    echo "Test 7: Required fields present"

    cat > "$TEST_DIR/fields-test.md" << 'EOF'
## Task: Complete Task
**Category**: Testing
**Priority**: 1

Task description here.

### Acceptance Criteria
- First criterion
- Second criterion
EOF

    ../ralph-loop "$TEST_DIR/fields-test.md" > /dev/null 2>&1 || true

    if [ -f "$TEST_DIR/fields-test.json" ]; then
        local all_present=true

        for field in "id" "title" "category" "priority" "description" "acceptanceCriteria" "passes" "completedAt" "attempts"; do
            if ! grep -q "\"$field\":" "$TEST_DIR/fields-test.json"; then
                fail "Required field '$field' missing"
                all_present=false
            fi
        done

        if [ "$all_present" = true ]; then
            pass "All required fields present in JSON"
        fi
    else
        fail "JSON file not created"
    fi
}

# Main test execution
main() {
    echo "========================================"
    echo "Markdown to JSON Conversion Test Suite"
    echo "========================================"

    setup

    test_file_type_detection
    test_markdown_parsing
    test_task_ids
    test_task_initialization
    test_preserve_markdown
    test_use_existing_json
    test_required_fields

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
