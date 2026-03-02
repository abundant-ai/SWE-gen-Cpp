#!/bin/bash

cd /app/src

export CI=true

# DO NOT copy test files - we want to check the current state after solve.sh has been applied (or not)
# For NOP agent: files are in BASE (buggy) state
# For Oracle agent: solve.sh applies fix.patch, so files should be in HEAD (fixed) state

# Test 1: Check if executor.go has the shardTestCases function (this is the main fix)
if grep -q "func shardTestCases" tests/harness/executor/executor.go; then
    echo "✓ shardTestCases function found in executor.go"
    shard_func_found=0
else
    echo "✗ shardTestCases function NOT found in executor.go"
    shard_func_found=1
fi

# Test 2: Check if executor.go uses TEST_TOTAL_SHARDS environment variable
if grep -q "TEST_TOTAL_SHARDS" tests/harness/executor/executor.go; then
    echo "✓ TEST_TOTAL_SHARDS environment variable used"
    shard_env_found=0
else
    echo "✗ TEST_TOTAL_SHARDS environment variable NOT used"
    shard_env_found=1
fi

# Test 3: Check if executor.go creates TEST_SHARD_STATUS_FILE
if grep -q "TEST_SHARD_STATUS_FILE" tests/harness/executor/executor.go; then
    echo "✓ TEST_SHARD_STATUS_FILE handling found"
    shard_file_handling=0
else
    echo "✗ TEST_SHARD_STATUS_FILE handling NOT found"
    shard_file_handling=1
fi

# Test 4: Check if BUILD file has sh_test targets
if grep -q "sh_test" tests/harness/executor/BUILD; then
    echo "✓ sh_test targets found in BUILD file"
    sh_test_found=0
else
    echo "✗ sh_test targets NOT found in BUILD file"
    sh_test_found=1
fi

# Test 5: Check if BUILD file defines executor_cc_test, executor_java_test, executor_python_test
if grep -q 'executor_.*_test' tests/harness/executor/BUILD; then
    echo "✓ executor test targets found in BUILD file"
    test_targets_found=0
else
    echo "✗ executor test targets NOT found in BUILD file"
    test_targets_found=1
fi

# Overall test passes if all checks pass
if [ $shard_func_found -eq 0 ] && [ $shard_env_found -eq 0 ] && [ $shard_file_handling -eq 0 ] && [ $sh_test_found -eq 0 ] && [ $test_targets_found -eq 0 ]; then
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
