#!/bin/bash

cd /app/src

# Set environment variables for tests
export CI=true
export USE_BAZEL_VERSION=7.6.1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "compatibility/smoke"
cp "/tests/compatibility/smoke/StaleGencodeSmokeTest.java" "compatibility/smoke/StaleGencodeSmokeTest.java"

# Run only the StaleGencodeSmokeTest using Bazel
# --test_output=all shows all test output including build errors
bazel test //compatibility/smoke:stale_gencode_smoke_test_v3.19.0 --test_output=all
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
