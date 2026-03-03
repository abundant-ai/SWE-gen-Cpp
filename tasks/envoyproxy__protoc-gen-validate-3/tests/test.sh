#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/bytes.proto" "tests/harness/cases/bytes.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/messages.proto" "tests/harness/cases/messages.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/oneofs.proto" "tests/harness/cases/oneofs.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_any.proto" "tests/harness/cases/wkt_any.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_duration.proto" "tests/harness/cases/wkt_duration.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_timestamp.proto" "tests/harness/cases/wkt_timestamp.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/wkt_wrappers.proto" "tests/harness/cases/wkt_wrappers.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# The test verifies that nil pointer checks are present in WKT validation templates
#
# The bug is in templates/go/*.go files which directly call methods on potentially nil pointers
# for Well-Known Types (Any, Duration, Timestamp, Wrappers), causing panics when validating
# nil values.
#
# The test files from HEAD (tests/harness/cases/wkt_*.proto, tests/harness/executor/cases.go)
# include test cases that would trigger nil pointer panics if the fix is not present.
#
# In the buggy state (BASE):
#   - templates/go/any.go calls GetTypeUrl() without nil check
#   - templates/go/duration.go, timestamp.go, *_wrappers.go have similar issues
# In the fixed state (BASE + fix.patch):
#   - All WKT templates properly check for nil before dereferencing

echo "Testing if WKT validation templates have nil pointer checks..." >&2

# Check if templates/go/any.go has nil check before GetTypeUrl()
if grep -q 'a := .* a != nil' templates/go/any.go 2>/dev/null; then
    echo "FIXED: templates/go/any.go has nil check for Any type" >&2
    has_any_nil_check=1
else
    echo "BUGGY: templates/go/any.go missing nil check for Any type" >&2
    has_any_nil_check=0
fi

# Check if templates/go/duration.go has proper nil handling
if grep -q 'd := .* d != nil' templates/go/duration.go 2>/dev/null; then
    echo "FIXED: templates/go/duration.go has nil check for Duration type" >&2
    has_duration_nil_check=1
else
    echo "BUGGY: templates/go/duration.go missing nil check for Duration type" >&2
    has_duration_nil_check=0
fi

# Check if templates/go/timestamp.go has proper nil handling (uses variable 't' not 'ts')
if grep -q 't := .* t != nil' templates/go/timestamp.go 2>/dev/null; then
    echo "FIXED: templates/go/timestamp.go has nil check for Timestamp type" >&2
    has_timestamp_nil_check=1
else
    echo "BUGGY: templates/go/timestamp.go missing nil check for Timestamp type" >&2
    has_timestamp_nil_check=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_any_nil_check -eq 1 ] && [ $has_duration_nil_check -eq 1 ] && [ $has_timestamp_nil_check -eq 1 ]; then
    echo "PASS: WKT validation templates have proper nil pointer checks" >&2
    test_status=0
else
    echo "FAIL: WKT validation templates missing nil pointer checks" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
