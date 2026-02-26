#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_iters_test.cc" "test/benchmark_min_time_flag_iters_test.cc"
mkdir -p "test"
cp "/tests/benchmark_min_time_flag_time_test.cc" "test/benchmark_min_time_flag_time_test.cc"
mkdir -p "test"
cp "/tests/min_time_parse_gtest.cc" "test/min_time_parse_gtest.cc"

# Rebuild to compile the updated test files
echo "Rebuilding to verify compilation..."
if cmake --build build --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ Build succeeded"
else
  echo "✗ Build failed"
  cat /tmp/build.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the specific test binaries for min_time tests
echo "Running benchmark_min_time_flag_iters_test..."
./build/test/benchmark_min_time_flag_iters_test
test_status1=$?

echo "Running benchmark_min_time_flag_time_test..."
./build/test/benchmark_min_time_flag_time_test
test_status2=$?

echo "Running min_time_parse_gtest..."
./build/test/min_time_parse_gtest
test_status3=$?

# Overall test status: fail if any test failed
test_status=0
if [ $test_status1 -ne 0 ] || [ $test_status2 -ne 0 ] || [ $test_status3 -ne 0 ]; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
