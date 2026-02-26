#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/test_containers.cpp" "test/test_containers.cpp"

# Rebuild tests with updated test files
cd build
cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON

# Build only the test_containers targets (not all tests which may fail due to emojis in test.cpp)
cmake --build . --target test_containers-cpp17 || true
cmake --build . --target test_containers-cpp20 || true
cmake --build . --target test_containers-cpp23 || true

# Run only the test_containers tests (the specific tests for this PR)
ctest -R test_containers -V
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
