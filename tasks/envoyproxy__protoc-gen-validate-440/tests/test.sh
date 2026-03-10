#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/executor.go" "tests/harness/executor/executor.go"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/executor_test.sh" "tests/harness/executor/executor_test.sh"
chmod +x "tests/harness/executor/executor_test.sh"

# Test if the Bazel test infrastructure is properly set up
# PR #440 adds:
# 1. sh_test targets in BUILD for cc, java, python
# 2. shardTestCases function in executor.go
# 3. executor_test.sh wrapper script

echo "Checking if sh_test targets are defined in BUILD file..." >&2
if grep -q 'sh_test' tests/harness/executor/BUILD && \
   grep -q 'executor_.*_test' tests/harness/executor/BUILD && \
   grep -q 'for lang in.*cc.*java.*python' tests/harness/executor/BUILD; then
    echo "PASS: BUILD file has sh_test targets" >&2
    has_build=1
else
    echo "FAIL: BUILD file missing sh_test targets" >&2
    has_build=0
fi

echo "Checking if shardTestCases function exists in executor.go..." >&2
if grep -q 'func shardTestCases' tests/harness/executor/executor.go && \
   grep -q 'TEST_TOTAL_SHARDS' tests/harness/executor/executor.go && \
   grep -q 'TEST_SHARD_INDEX' tests/harness/executor/executor.go; then
    echo "PASS: executor.go has shardTestCases function" >&2
    has_executor=1
else
    echo "FAIL: executor.go missing shardTestCases function" >&2
    has_executor=0
fi

echo "Checking if executor_test.sh exists and is executable..." >&2
if [ -f tests/harness/executor/executor_test.sh ] && [ -x tests/harness/executor/executor_test.sh ]; then
    echo "PASS: executor_test.sh exists and is executable" >&2
    has_test_script=1
else
    echo "FAIL: executor_test.sh missing or not executable" >&2
    has_test_script=0
fi

echo "Checking if Makefile has bazel-tests target..." >&2
if grep -q 'bazel-tests:' Makefile && \
   grep -q 'bazel test //tests/\.\.\.' Makefile; then
    echo "PASS: Makefile has bazel-tests target" >&2
    has_makefile=1
else
    echo "FAIL: Makefile missing bazel-tests target" >&2
    has_makefile=0
fi

# Test passes if all checks pass
if [ $has_build -eq 1 ] && [ $has_executor -eq 1 ] && [ $has_test_script -eq 1 ] && [ $has_makefile -eq 1 ]; then
    echo "PASS: All Bazel test infrastructure is present" >&2
    test_status=0
else
    echo "FAIL: Some Bazel test infrastructure is missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
