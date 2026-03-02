#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Check if the CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST option exists in CMakeLists.txt
# BASE state (without the fix) doesn't have this option
if ! grep -q "CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST" CMakeLists.txt; then
  # Option not found - BASE state fails
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Reconfigure with the CROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST option enabled
cmake -DCROW_RETURNS_OK_ON_HTTP_OPTIONS_REQUEST=ON -B build

# Rebuild only the unittest target with the updated test file (single-threaded to save memory)
cmake --build build --config Release --target unittest -- -j1
build_status=$?

# If build fails, tests fail
if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $build_status
fi

# Run the unittest executable (Catch2 framework)
./build/tests/unittest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
