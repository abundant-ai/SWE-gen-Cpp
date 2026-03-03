#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Test version/soversion checks in CMakeLists.txt
# The fix adds checks in tests/CMakeLists.txt that verify the VERSION and SOVERSION
# properties are set on the simdjson target.
#
# In the BUGGY state (BASE):
#   - src/CMakeLists.txt doesn't set VERSION/SOVERSION properties
#   - tests/CMakeLists.txt doesn't have checks for these properties
#   - CMake configuration should succeed
#
# In the FIXED state (HEAD):
#   - src/CMakeLists.txt sets VERSION/SOVERSION properties
#   - tests/CMakeLists.txt has checks that FATAL_ERROR if properties aren't set
#   - CMake configuration should succeed (properties are set)

# Clean and reconfigure
rm -rf build
if cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1; then
    # Configuration succeeded
    test_status=0
else
    # Configuration failed (expected in BUGGY state when fix is applied, because VERSION/SOVERSION aren't set)
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
