#!/usr/bin/env bash

# Master test script - runs all test suites

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test result tracking
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITES_PASSED=0
SUITES_FAILED=0

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                        RALPH LOOP TEST SUITE                               ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Array of test scripts to run
TEST_SCRIPTS=(
    "test-conversion.sh"
    "test-validation.sh"
    "test-resume.sh"
    "test-help.sh"
    "test-analysis.sh"
    "test-completion-detection.sh"
)

# Run each test suite
for test_script in "${TEST_SCRIPTS[@]}"; do
    test_path="$SCRIPT_DIR/$test_script"

    if [ ! -f "$test_path" ]; then
        echo -e "${RED}✗ Test script not found: $test_script${NC}"
        SUITES_FAILED=$((SUITES_FAILED + 1))
        continue
    fi

    if [ ! -x "$test_path" ]; then
        echo -e "${YELLOW}⚠ Making $test_script executable${NC}"
        chmod +x "$test_path"
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: $test_script${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Run the test and capture results
    if "$test_path"; then
        echo -e "${GREEN}✓ $test_script PASSED${NC}"
        SUITES_PASSED=$((SUITES_PASSED + 1))
    else
        echo -e "${RED}✗ $test_script FAILED${NC}"
        SUITES_FAILED=$((SUITES_FAILED + 1))
    fi
done

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                           FINAL TEST SUMMARY                               ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_SUITES=$((SUITES_PASSED + SUITES_FAILED))

echo "Test Suites:"
echo -e "  ${GREEN}Passed: $SUITES_PASSED${NC}"
echo -e "  ${RED}Failed: $SUITES_FAILED${NC}"
echo "  Total:  $TOTAL_SUITES"
echo ""

if [ $SUITES_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        ✓ ALL TESTS PASSED                                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                        ✗ SOME TESTS FAILED                                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Failed test suites:"
    for test_script in "${TEST_SCRIPTS[@]}"; do
        test_path="$SCRIPT_DIR/$test_script"
        if [ -f "$test_path" ] && [ -x "$test_path" ]; then
            if ! "$test_path" > /dev/null 2>&1; then
                echo -e "  ${RED}✗ $test_script${NC}"
            fi
        fi
    done
    exit 1
fi
