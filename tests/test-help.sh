#!/usr/bin/env bash

# Test suite for help output completeness

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

# Test 1: Help triggered by --help flag
test_help_flag() {
    echo ""
    echo "Test 1: --help flag triggers help output"

    ../ralph-loop --help > "$TEST_DIR/help-output.txt" 2>&1 || true

    if [ -s "$TEST_DIR/help-output.txt" ]; then
        pass "--help flag produces output"
    else
        fail "--help flag produces no output"
    fi
}

# Test 2: Help triggered by no arguments
test_no_args() {
    echo ""
    echo "Test 2: No arguments triggers help output"

    ../ralph-loop > "$TEST_DIR/no-args-output.txt" 2>&1 || true

    if [ -s "$TEST_DIR/no-args-output.txt" ]; then
        pass "No arguments produces output"
    else
        fail "No arguments produces no output"
    fi
}

# Test 3: Includes "What is Ralph Loop?" introduction
test_introduction() {
    echo ""
    echo "Test 3: Help includes introduction"

    ../ralph-loop --help > "$TEST_DIR/help-intro.txt" 2>&1 || true

    if grep -qi "what is\|ralph loop\|introduction" "$TEST_DIR/help-intro.txt"; then
        pass "Help includes 'What is Ralph Loop?' introduction"
    else
        fail "Help missing introduction section"
    fi
}

# Test 4: Shows 3-step Quick Start Workflow
test_quick_start() {
    echo ""
    echo "Test 4: Help includes Quick Start Workflow"

    ../ralph-loop --help > "$TEST_DIR/help-quickstart.txt" 2>&1 || true

    if grep -qi "quick start\|workflow\|getting started" "$TEST_DIR/help-quickstart.txt"; then
        pass "Help includes Quick Start section"
    else
        fail "Help missing Quick Start section"
    fi
}

# Test 5: Displays usage syntax
test_usage_syntax() {
    echo ""
    echo "Test 5: Help displays usage syntax"

    ../ralph-loop --help > "$TEST_DIR/help-usage.txt" 2>&1 || true

    if grep -qi "usage:\|synopsis" "$TEST_DIR/help-usage.txt"; then
        pass "Help includes usage syntax"
    else
        fail "Help missing usage syntax"
    fi
}

# Test 6: Documents all option flags
test_option_descriptions() {
    echo ""
    echo "Test 6: Help documents all options"

    ../ralph-loop --help > "$TEST_DIR/help-options.txt" 2>&1 || true

    local all_flags_present=true

    # Check for each flag
    for flag in "max-iterations" "verbose" "debug" "resume" "analyze-prd" "help"; do
        if ! grep -q "$flag" "$TEST_DIR/help-options.txt"; then
            fail "Option --$flag not documented in help"
            all_flags_present=false
        fi
    done

    if [ "$all_flags_present" = true ]; then
        pass "All option flags documented"
    fi
}

# Test 7: Includes usage examples
test_usage_examples() {
    echo ""
    echo "Test 7: Help includes usage examples"

    ../ralph-loop --help > "$TEST_DIR/help-examples.txt" 2>&1 || true

    if grep -qi "example" "$TEST_DIR/help-examples.txt"; then
        local example_count=$(grep -ci "example" "$TEST_DIR/help-examples.txt")
        if [ "$example_count" -ge 3 ]; then
            pass "Help includes multiple usage examples ($example_count found)"
        else
            fail "Help has too few examples (need at least 3, found $example_count)"
        fi
    else
        fail "Help missing usage examples"
    fi
}

# Test 8: Provides PRD writing guidelines
test_prd_guidelines() {
    echo ""
    echo "Test 8: Help includes PRD writing guidelines"

    ../ralph-loop --help > "$TEST_DIR/help-guidelines.txt" 2>&1 || true

    if grep -qi "prd\|writing" "$TEST_DIR/help-guidelines.txt" && \
       grep -qi "guideline\|best practice\|how to write" "$TEST_DIR/help-guidelines.txt"; then
        pass "Help includes PRD writing guidelines"
    else
        fail "Help missing PRD writing guidelines"
    fi
}

# Test 9: Includes troubleshooting section
test_troubleshooting() {
    echo ""
    echo "Test 9: Help includes troubleshooting section"

    ../ralph-loop --help > "$TEST_DIR/help-troubleshoot.txt" 2>&1 || true

    if grep -qi "troubleshoot\|common.*error\|faq\|problem" "$TEST_DIR/help-troubleshoot.txt"; then
        pass "Help includes troubleshooting section"
    else
        fail "Help missing troubleshooting section"
    fi
}

# Test 10: Shows tips for success
test_tips_section() {
    echo ""
    echo "Test 10: Help includes tips for success"

    ../ralph-loop --help > "$TEST_DIR/help-tips.txt" 2>&1 || true

    if grep -qi "tip\|advice\|recommendation\|success" "$TEST_DIR/help-tips.txt"; then
        pass "Help includes tips for success"
    else
        fail "Help missing tips section"
    fi
}

# Test 11: Lists files that will be created
test_files_created() {
    echo ""
    echo "Test 11: Help lists files that will be created"

    ../ralph-loop --help > "$TEST_DIR/help-files.txt" 2>&1 || true

    if grep -q "progress.txt" "$TEST_DIR/help-files.txt" || \
       grep -qi "files.*created\|output.*files" "$TEST_DIR/help-files.txt"; then
        pass "Help mentions files that will be created"
    else
        fail "Help does not mention output files"
    fi
}

# Test 12: Troubleshooting addresses key scenarios
test_troubleshooting_coverage() {
    echo ""
    echo "Test 12: Troubleshooting covers key scenarios"

    ../ralph-loop --help > "$TEST_DIR/help-troubleshoot-detail.txt" 2>&1 || true

    local coverage_count=0

    if grep -qi "validation" "$TEST_DIR/help-troubleshoot-detail.txt"; then
        coverage_count=$((coverage_count + 1))
    fi

    if grep -qi "iteration\|max" "$TEST_DIR/help-troubleshoot-detail.txt"; then
        coverage_count=$((coverage_count + 1))
    fi

    if grep -qi "conversion\|markdown" "$TEST_DIR/help-troubleshoot-detail.txt"; then
        coverage_count=$((coverage_count + 1))
    fi

    if [ "$coverage_count" -ge 2 ]; then
        pass "Troubleshooting covers key scenarios ($coverage_count/3)"
    else
        fail "Troubleshooting coverage insufficient ($coverage_count/3)"
    fi
}

# Test 13: Help includes examples for major flags
test_flag_examples() {
    echo ""
    echo "Test 13: Help includes examples for major flags"

    ../ralph-loop --help > "$TEST_DIR/help-flag-examples.txt" 2>&1 || true

    local flag_example_count=0

    for flag in "max-iterations" "verbose" "resume" "analyze-prd"; do
        if grep -q "$flag" "$TEST_DIR/help-flag-examples.txt"; then
            flag_example_count=$((flag_example_count + 1))
        fi
    done

    if [ "$flag_example_count" -ge 3 ]; then
        pass "Help includes examples for major flags ($flag_example_count/4)"
    else
        fail "Help missing examples for major flags ($flag_example_count/4)"
    fi
}

# Main test execution
main() {
    echo "========================================"
    echo "Help Output Test Suite"
    echo "========================================"

    setup

    test_help_flag
    test_no_args
    test_introduction
    test_quick_start
    test_usage_syntax
    test_option_descriptions
    test_usage_examples
    test_prd_guidelines
    test_troubleshooting
    test_tips_section
    test_files_created
    test_troubleshooting_coverage
    test_flag_examples

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
