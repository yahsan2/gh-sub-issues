#!/bin/bash
# Integration test script for gh-sub-issues

set -e

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
    
    if output=$($command 2>&1); then
        if [[ -z "$expected" ]] || [[ "$output" == *"$expected"* ]]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Expected: $expected"
            echo "  Got: $output"
            ((TESTS_FAILED++))
        fi
    else
        if [[ "$expected" == "ERROR:"* ]]; then
            if [[ "$output" == *"${expected#ERROR:}"* ]]; then
                echo -e "${GREEN}✓ PASSED${NC} (expected error)"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}✗ FAILED${NC}"
                echo "  Expected error: ${expected#ERROR:}"
                echo "  Got: $output"
                ((TESTS_FAILED++))
            fi
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Command failed unexpectedly: $output"
            ((TESTS_FAILED++))
        fi
    fi
}

# Build the binary
echo "Building gh-sub-issues..."
go build -o gh-sub-issues || exit 1
echo ""

# Test 1: Help text
echo "=== Basic Command Tests ==="
run_test "Help command" "./gh-sub-issues --help" "A GitHub CLI extension that adds sub-issue management"
run_test "Add help" "./gh-sub-issues add --help" "Link an existing issue to a parent issue"

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
run_test "Invalid URL format" "./gh-sub-issues add https://example.com/123 456 --repo test/repo" "ERROR:not a GitHub URL"
run_test "Non-issue URL" "./gh-sub-issues add https://github.com/owner/repo/pull/123 456 --repo test/repo" "ERROR:not an issue URL"

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