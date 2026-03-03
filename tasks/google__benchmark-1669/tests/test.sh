#!/bin/bash

cd /app/src

# Verify the fix: check that test/CMakeLists.txt contains the correct MSVC detection
# Buggy version: if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
# Fixed version: if(NOT (MSVC OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC"))

if grep -q 'if(NOT (MSVC OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC"))' test/CMakeLists.txt; then
    echo "✓ Fix verified"
    test_status=0
else
    echo "✗ Bug present"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
