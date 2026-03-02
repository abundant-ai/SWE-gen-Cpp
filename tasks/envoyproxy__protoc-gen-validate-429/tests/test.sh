#!/bin/bash

cd /app/src

export CI=true

# Verify that the current file state matches the expected fixed versions
# For NOP: Files are in buggy state, comparison fails (reward=0)
# For Oracle: solve.sh applies fix.patch, files match expected state (reward=1)

if diff -q tests/harness/executor/harness.go /tests/harness/executor/harness.go > /dev/null 2>&1; then
    echo "✓ harness.go matches expected fixed version"
    harness_correct=0
else
    echo "✗ harness.go doesn't match expected fixed version"
    harness_correct=1
fi

if diff -q tests/harness/executor/worker.go /tests/harness/executor/worker.go > /dev/null 2>&1; then
    echo "✓ worker.go matches expected fixed version"
    worker_correct=0
else
    echo "✗ worker.go doesn't match expected fixed version"
    worker_correct=1
fi

if [ $harness_correct -eq 0 ] && [ $worker_correct -eq 0 ]; then
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
