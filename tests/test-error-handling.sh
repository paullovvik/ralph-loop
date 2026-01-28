#!/usr/bin/env bash

# Test Error Handling and Contextual Help
# Tests all error scenarios and verifies helpful error messages

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RALPH_LOOP="$PROJECT_DIR/ralph-loop"
TEST_DIR="$(mktemp -d)"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}      TEST: Error Handling and Contextual Help${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
test_error_message() {
    local test_name="$1"
    local expected_keyword="$2"
    shift 2
    local command=("$@")

    echo -n "Testing: $test_name... "

    if output=$("${command[@]}" 2>&1); then
        echo -e "${RED}FAIL${NC} (command succeeded but should have failed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        if echo "$output" | grep -iq "$expected_keyword"; then
            echo -e "${GREEN}PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}FAIL${NC} (missing expected keyword: $expected_keyword)"
            echo "Output was:"
            echo "$output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Test 1: File not found error
echo -e "${BLUE}Test 1: File not found error${NC}"
test_error_message "File not found" "not found" "$RALPH_LOOP" "nonexistent.md"
echo ""

# Test 2: Help is shown when no arguments provided (not an error)
echo -e "${BLUE}Test 2: Help shown when no arguments${NC}"
echo -n "Testing: No arguments shows help... "
if output=$("$RALPH_LOOP" 2>&1); then
    if echo "$output" | grep -q "RALPH LOOP"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (no help shown)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}FAIL${NC} (command failed)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test 3: Invalid option
echo -e "${BLUE}Test 3: Invalid option${NC}"
test_error_message "Invalid option" "Unknown option" "$RALPH_LOOP" "--invalid-flag"
echo ""

# Test 4: Invalid --max-iterations
echo -e "${BLUE}Test 4: Invalid --max-iterations value${NC}"
cat > "$TEST_DIR/simple.md" << 'EOF'
## Task: Test task
**Category**: Test
**Priority**: 1

### Acceptance Criteria
- Test passes
EOF

test_error_message "Invalid max-iterations (non-numeric)" "positive integer" "$RALPH_LOOP" "$TEST_DIR/simple.md" --max-iterations abc
echo ""

# Test 5: Create invalid PRD (missing title)
echo -e "${BLUE}Test 5: PRD validation - missing title${NC}"
cat > "$TEST_DIR/invalid-missing-title.json" << 'EOF'
{
  "tasks": []
}
EOF
test_error_message "Missing title field" "Missing required field 'title'" "$RALPH_LOOP" "$TEST_DIR/invalid-missing-title.json"
echo ""

# Test 6: Create invalid PRD (duplicate priorities)
echo -e "${BLUE}Test 6: PRD validation - duplicate priorities${NC}"
cat > "$TEST_DIR/invalid-dup-priority.json" << 'EOF'
{
  "title": "Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Task 1",
      "category": "Test",
      "priority": 1,
      "acceptanceCriteria": ["Test 1"],
      "passes": false
    },
    {
      "id": "task-2",
      "title": "Task 2",
      "category": "Test",
      "priority": 1,
      "acceptanceCriteria": ["Test 2"],
      "passes": false
    }
  ]
}
EOF
test_error_message "Duplicate priority" "Duplicate priority" "$RALPH_LOOP" "$TEST_DIR/invalid-dup-priority.json"
echo ""

# Test 7: Invalid PRD (empty acceptance criteria)
echo -e "${BLUE}Test 7: PRD validation - empty acceptance criteria${NC}"
cat > "$TEST_DIR/invalid-empty-criteria.json" << 'EOF'
{
  "title": "Test PRD",
  "tasks": [
    {
      "id": "task-1",
      "title": "Task 1",
      "category": "Test",
      "priority": 1,
      "acceptanceCriteria": [],
      "passes": false
    }
  ]
}
EOF
test_error_message "Empty acceptance criteria" "empty acceptanceCriteria" "$RALPH_LOOP" "$TEST_DIR/invalid-empty-criteria.json"
echo ""

# Test 8: Wrong file extension
echo -e "${BLUE}Test 8: Wrong file extension${NC}"
cat > "$TEST_DIR/test.txt" << 'EOF'
Some text
EOF
test_error_message "Wrong extension" "must have .md or .json extension" "$RALPH_LOOP" "$TEST_DIR/test.txt"
echo ""

# Test 9: Verify help output includes troubleshooting
echo -e "${BLUE}Test 9: Help output includes troubleshooting section${NC}"
if "$RALPH_LOOP" --help | grep -q "TROUBLESHOOTING"; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test 10: Verify suggestion to use --analyze-prd in validation errors
echo -e "${BLUE}Test 10: Validation errors suggest --analyze-prd${NC}"
if output=$("$RALPH_LOOP" "$TEST_DIR/invalid-empty-criteria.json" 2>&1); then
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    if echo "$output" | grep -q "analyze-prd"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (missing --analyze-prd suggestion)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi
echo ""

# Test 11: Check permission error message (create unreadable file)
echo -e "${BLUE}Test 11: Permission error provides chmod suggestion${NC}"
cat > "$TEST_DIR/unreadable.md" << 'EOF'
## Task: Test
**Category**: Test
**Priority**: 1

### Acceptance Criteria
- Test
EOF
chmod 000 "$TEST_DIR/unreadable.md"
if output=$("$RALPH_LOOP" "$TEST_DIR/unreadable.md" 2>&1); then
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    if echo "$output" | grep -iq "chmod"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (missing chmod suggestion)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi
chmod 644 "$TEST_DIR/unreadable.md"
echo ""

# Clean up
rm -rf "$TEST_DIR"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All error handling tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
