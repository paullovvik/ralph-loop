#!/usr/bin/env bash

# Test suite for model selection: config loading, CLI overrides, tier
# mapping, escalation logic, and find_next_task blocked-task skipping.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_LOOP="$SCRIPT_DIR/../ralph-loop"

setup() {
    TEST_DIR=$(mktemp -d)
    info "Created test directory: $TEST_DIR"
}

cleanup() {
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        info "Cleaned up test directory"
    fi
}

# ── Unit tests: source the script and call helpers directly ───────────────────

source_helpers() {
    # shellcheck source=/dev/null
    source "$RALPH_LOOP"
}

test_tier_to_id() {
    echo ""
    echo "Test: tier_to_id maps tier names to model IDs"
    (
        source_helpers
        [ "$(tier_to_id haiku)"  = "claude-haiku-4-5"  ] || exit 1
        [ "$(tier_to_id sonnet)" = "claude-sonnet-4-6" ] || exit 1
        [ "$(tier_to_id opus)"   = "claude-opus-4-8"   ] || exit 1
    ) && pass "tier_to_id maps haiku/sonnet/opus correctly" \
      || fail "tier_to_id mapping wrong"
}

test_tier_rank_ordering() {
    echo ""
    echo "Test: tier_rank gives haiku<sonnet<opus"
    (
        source_helpers
        [ "$(tier_rank haiku)"  -lt "$(tier_rank sonnet)" ] || exit 1
        [ "$(tier_rank sonnet)" -lt "$(tier_rank opus)"   ] || exit 1
    ) && pass "tier_rank ordering is haiku<sonnet<opus" \
      || fail "tier_rank ordering wrong"
}

test_next_tier() {
    echo ""
    echo "Test: next_tier promotes one tier (opus is its own next)"
    (
        source_helpers
        [ "$(next_tier haiku)"  = "sonnet" ] || exit 1
        [ "$(next_tier sonnet)" = "opus"   ] || exit 1
        [ "$(next_tier opus)"   = "opus"   ] || exit 1
    ) && pass "next_tier promotes correctly" \
      || fail "next_tier wrong"
}

test_resolve_defaults() {
    echo ""
    echo "Test: resolve_model_settings applies defaults when nothing set"
    (
        source_helpers
        TARGET_MODEL=""; ESCALATION_CAP=""; ESCALATION_THRESHOLD=""
        resolve_model_settings >/dev/null 2>&1
        [ "$TARGET_MODEL"        = "sonnet" ] || exit 1
        [ "$ESCALATION_CAP"      = "opus"   ] || exit 1
        [ "$ESCALATION_THRESHOLD" = "3"     ] || exit 1
    ) && pass "Defaults are sonnet/opus/3" \
      || fail "Defaults not applied correctly"
}

test_resolve_rejects_target_above_cap() {
    echo ""
    echo "Test: resolve_model_settings rejects target above cap"
    if (
        source_helpers
        TARGET_MODEL="opus"; ESCALATION_CAP="sonnet"; ESCALATION_THRESHOLD=3
        resolve_model_settings
    ) >/dev/null 2>&1; then
        fail "Should have rejected target=opus, cap=sonnet"
    else
        pass "Rejects target above cap"
    fi
}

test_resolve_rejects_bad_threshold() {
    echo ""
    echo "Test: resolve_model_settings rejects non-numeric threshold"
    if (
        source_helpers
        TARGET_MODEL="sonnet"; ESCALATION_CAP="opus"; ESCALATION_THRESHOLD="abc"
        resolve_model_settings
    ) >/dev/null 2>&1; then
        fail "Should have rejected threshold=abc"
    else
        pass "Rejects non-numeric threshold"
    fi
}

# ── Integration tests: run the script as a subprocess ─────────────────────────

test_invalid_target_model_flag() {
    echo ""
    echo "Test: --target-model with invalid tier exits with error"
    setup
    cat > "$TEST_DIR/p.json" << 'EOF'
{"title":"t","tasks":[{"id":"task-1","title":"x","category":"c","priority":1,"acceptanceCriteria":["a"],"passes":false}]}
EOF
    "$RALPH_LOOP" "$TEST_DIR/p.json" --target-model garbage > "$TEST_DIR/out.txt" 2>&1 || true

    if grep -qi "invalid model tier\|unknown model tier" "$TEST_DIR/out.txt"; then
        pass "Rejects invalid tier name"
    else
        fail "Did not reject invalid tier"
        cat "$TEST_DIR/out.txt"
    fi
    cleanup
}

test_config_file_loads() {
    echo ""
    echo "Test: config file is sourced via RALPH_LOOP_CONFIG"
    setup
    # Config sets a bad cap so the script will fail validation — proving the
    # config was actually read.
    cat > "$TEST_DIR/cfg" << 'EOF'
TARGET_MODEL=opus
ESCALATION_CAP=sonnet
EOF
    cat > "$TEST_DIR/p.json" << 'EOF'
{"title":"t","tasks":[{"id":"task-1","title":"x","category":"c","priority":1,"acceptanceCriteria":["a"],"passes":false}]}
EOF
    RALPH_LOOP_CONFIG="$TEST_DIR/cfg" "$RALPH_LOOP" "$TEST_DIR/p.json" > "$TEST_DIR/out.txt" 2>&1 || true

    if grep -qi "cannot be higher than" "$TEST_DIR/out.txt"; then
        pass "Config file values are loaded and validated"
    else
        fail "Config file not loaded"
        cat "$TEST_DIR/out.txt"
    fi
    cleanup
}

test_cli_overrides_config() {
    echo ""
    echo "Test: CLI flag overrides config-file value"
    setup
    # Config sets a valid combo. CLI flag breaks it. If the override works,
    # we get the cap-vs-target validation error.
    cat > "$TEST_DIR/cfg" << 'EOF'
TARGET_MODEL=haiku
ESCALATION_CAP=sonnet
EOF
    cat > "$TEST_DIR/p.json" << 'EOF'
{"title":"t","tasks":[{"id":"task-1","title":"x","category":"c","priority":1,"acceptanceCriteria":["a"],"passes":false}]}
EOF
    RALPH_LOOP_CONFIG="$TEST_DIR/cfg" "$RALPH_LOOP" "$TEST_DIR/p.json" \
        --target-model opus > "$TEST_DIR/out.txt" 2>&1 || true

    if grep -qi "cannot be higher than" "$TEST_DIR/out.txt"; then
        pass "CLI --target-model overrode config TARGET_MODEL"
    else
        fail "CLI flag did not override config"
        cat "$TEST_DIR/out.txt"
    fi
    cleanup
}

test_find_next_task_skips_blocked() {
    echo ""
    echo "Test: find_next_task skips tasks with blocked=true"
    setup
    cat > "$TEST_DIR/p.json" << 'EOF'
{
  "title":"t",
  "tasks":[
    {"id":"task-1","title":"a","priority":1,"passes":false,"blocked":true,"acceptanceCriteria":["x"]},
    {"id":"task-2","title":"b","priority":2,"passes":false,"acceptanceCriteria":["x"]}
  ]
}
EOF
    (
        source_helpers
        JSON_FILE="$TEST_DIR/p.json"
        result=$(find_next_task)
        [ "$result" = "task-2" ] || { echo "got: '$result'"; exit 1; }
    ) && pass "find_next_task returns task-2 (skips blocked task-1)" \
      || fail "find_next_task did not skip blocked task"
    cleanup
}

# ── Run all tests ─────────────────────────────────────────────────────────────

main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "  Model Selection Test Suite"
    echo "════════════════════════════════════════════════════════════════"

    test_tier_to_id
    test_tier_rank_ordering
    test_next_tier
    test_resolve_defaults
    test_resolve_rejects_target_above_cap
    test_resolve_rejects_bad_threshold
    test_invalid_target_model_flag
    test_config_file_loads
    test_cli_overrides_config
    test_find_next_task_skips_blocked

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "════════════════════════════════════════════════════════════════"

    [ "$TESTS_FAILED" -eq 0 ]
}

main "$@"
