#!/bin/bash
# Integration test script for gh-sub-issues

# Don't exit on error immediately - we handle errors ourselves
set +e

echo "🧪 Running Integration Tests for gh-sub-issues"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Testing: $test_name... "
    
    # Run command and capture both stdout and stderr
    output=$($command 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if [[ -z "$expected" ]] || [[ "$output" == *"$expected"* ]]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Expected: $expected"
            echo "  Got: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        # Command failed (non-zero exit code)
        if [[ "$expected" == "ERROR:"* ]]; then
            # We expected an error
            if [[ "$output" == *"${expected#ERROR:}"* ]]; then
                echo -e "${GREEN}✓ PASSED${NC} (expected error)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗ FAILED${NC}"
                echo "  Expected error containing: ${expected#ERROR:}"
                echo "  Got: $output"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        else
            # Command failed but we didn't expect an error
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Command failed unexpectedly with exit code $exit_code"
            echo "  Output: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Build the binary
echo "Building gh-sub-issues..."
if ! go build -o gh-sub-issues; then
    echo "Failed to build gh-sub-issues"
    exit 1
fi
echo ""

# Test 1: Help text
echo "=== Basic Command Tests ==="
run_test "Help command" "./gh-sub-issues --help" "A GitHub CLI extension that adds sub-issue management"
run_test "Add help" "./gh-sub-issues add --help" "Link an existing issue to a parent issue"
run_test "List help" "./gh-sub-issues list --help" "List all sub-issues connected to a parent issue"

# Test 2: Version
run_test "Version" "./gh-sub-issues --version" "version"

# Test 3: Invalid arguments
echo ""
echo "=== Error Handling Tests ==="
run_test "Missing arguments" "./gh-sub-issues add" "ERROR:accepts 2 arg(s), received 0"
run_test "Too many arguments" "./gh-sub-issues add 1 2 3" "ERROR:accepts 2 arg(s), received 3"
run_test "Invalid issue number" "./gh-sub-issues add abc 123 --repo test/repo" "ERROR:invalid issue reference"
run_test "Invalid repo format" "./gh-sub-issues add 1 2 --repo invalid-format" "ERROR:invalid repository format"
run_test "Circular dependency" "./gh-sub-issues add 5 5 --repo test/repo" "ERROR:cannot add issue as its own sub-issue"

# Test 4: URL parsing tests
echo ""
echo "=== URL Parsing Tests ==="
run_test "Invalid URL format" "./gh-sub-issues add https://example.com/123 456 --repo test/repo" "ERROR:invalid GitHub issue URL format"
run_test "Non-issue URL" "./gh-sub-issues add https://github.com/owner/repo/pull/123 456 --repo test/repo" "ERROR:not an issue URL"

# Test 5: List command tests
echo ""
echo "=== List Command Tests ==="
run_test "List missing arguments" "./gh-sub-issues list" "ERROR:accepts 1 arg(s), received 0"
run_test "List too many arguments" "./gh-sub-issues list 1 2" "ERROR:accepts 1 arg(s), received 2"
run_test "List invalid issue number" "./gh-sub-issues list abc --repo test/repo" "ERROR:invalid issue reference"
run_test "List invalid repo format" "./gh-sub-issues list 1 --repo invalid-format" "ERROR:invalid repository format"

# Summary
echo ""
echo "=============================================="
echo -e "Test Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi