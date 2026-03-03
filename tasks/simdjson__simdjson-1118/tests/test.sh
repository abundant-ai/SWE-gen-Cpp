#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Clean build directory to ensure fresh build
rm -rf build

# The key behavioral difference:
# - BASE (buggy): SIMDJSON_BASH option does NOT exist → can't disable bash on FreeBSD → BROKEN
# - HEAD (fixed): SIMDJSON_BASH option exists → can disable bash on FreeBSD → FIXED
#
# Test strategy: Check if the option definition exists in the source file
# This is more direct than checking CMakeCache behavior

if grep -q "option(SIMDJSON_BASH" cmake/simdjson-flags.cmake; then
    # Option definition found - this is the FIXED state (HEAD, after fix.patch applied)
    echo "SUCCESS: SIMDJSON_BASH option exists, allowing bash to be disabled on FreeBSD"
    test_status=0
else
    # Option definition not found - this is the BUGGY state (BASE, before fix)
    echo "FAILURE: SIMDJSON_BASH option missing, cannot disable bash on FreeBSD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
