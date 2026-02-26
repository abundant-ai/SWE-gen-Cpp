#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/SelfTest/UsageTests"
cp "/tests/SelfTest/UsageTests/Benchmark.tests.cpp" "tests/SelfTest/UsageTests/Benchmark.tests.cpp"

# Rebuild after copying the updated test files
if ! cmake --build build; then
    echo "Build failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the "Skip benchmark macros" test with --skip-benchmarks flag
# This test should PASS in HEAD (with --skip-benchmarks feature) and FAIL in BASE (without it)
./build/tests/SelfTest "Skip benchmark macros" --reporter console --skip-benchmarks
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
