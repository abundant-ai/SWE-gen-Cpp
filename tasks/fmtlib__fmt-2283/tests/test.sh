#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/module-test.cc" "test/module-test.cc"

# Reconfigure CMake to pick up updated test files
# The test verifies that the module support code is present by checking for the
# "Module support is disabled" message (appears when FMT_CAN_MODULE check exists)
cd build
cmake_output=$(cmake .. 2>&1)
cmake_status=$?

echo "$cmake_output"

if [ $cmake_status -ne 0 ]; then
  echo "CMake configuration failed" >&2
  test_status=1
elif echo "$cmake_output" | grep -q "Module support is disabled"; then
  # The module support check code is present (fix applied)
  test_status=0
else
  # No module support message means the code is missing (BASE/buggy state)
  echo "Module support check not found in CMake output" >&2
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
