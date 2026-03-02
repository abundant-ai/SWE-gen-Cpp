#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Verify that the protobuf dependency update is correctly applied
# For NOP: Code is in buggy state (old protobuf v1.3.1), tests fail (reward=0)
# For Oracle: solve.sh applies fix.patch, protobuf v1.4.2 is restored, tests pass (reward=1)

echo "Checking if protobuf dependency is correctly updated..."

# Check if go.mod has the correct protobuf version
if grep -q 'github.com/golang/protobuf v1.4.2' go.mod; then
    echo "✓ go.mod has correct protobuf version (v1.4.2)"
    go_mod_correct=0
else
    echo "✗ go.mod has incorrect protobuf version"
    go_mod_correct=1
fi

# Check if RepeatedMinAndMaxItemLen message is present in the proto file
if grep -q 'message RepeatedMinAndMaxItemLen' tests/harness/cases/repeated.proto; then
    echo "✓ RepeatedMinAndMaxItemLen message found in repeated.proto"
    proto_message=0
else
    echo "✗ RepeatedMinAndMaxItemLen message not found in repeated.proto"
    proto_message=1
fi

# Check if the test cases for RepeatedMinAndMaxItemLen are present in cases.go
if grep -q 'repeated - min and max items len - valid' tests/harness/executor/cases.go; then
    echo "✓ Test cases for RepeatedMinAndMaxItemLen found in cases.go"
    test_cases=0
else
    echo "✗ Test cases for RepeatedMinAndMaxItemLen not found in cases.go"
    test_cases=1
fi

# Try to rebuild to verify dependencies work
echo "Attempting to rebuild with updated dependencies..."
if make build 2>&1; then
    echo "✓ Build succeeded with updated dependencies"
    build_success=0
else
    echo "✗ Build failed with current dependencies"
    build_success=1
fi

if [ $go_mod_correct -eq 0 ] && [ $proto_message -eq 0 ] && [ $test_cases -eq 0 ] && [ $build_success -eq 0 ]; then
    echo "All tests passed!"
    test_status=0
else
    echo "Some tests failed!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
