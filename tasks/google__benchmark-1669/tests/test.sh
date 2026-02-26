#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# This PR fixes MSVC detection logic in multiple CMake files to handle clang++ targeting MSVC ABI.
# The fix requires checking CMAKE_CXX_SIMULATE_ID in addition to MSVC.

echo "Verifying fix in CMakeLists.txt (main build file)..."
# Check main CMakeLists.txt for the fix (this is applied by solve.sh via fix.patch)
if grep -q 'if(NOT (MSVC OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC"))' CMakeLists.txt; then
  echo "✓ CMakeLists.txt: Found correct MSVC detection logic"
  main_ok=true
else
  echo "✗ CMakeLists.txt: Missing correct MSVC detection logic"
  main_ok=false
fi

echo -e "\nVerifying fix in test/CMakeLists.txt..."
# Check test/CMakeLists.txt for the fix (this is provided in /tests/)
if grep -q 'if(NOT (MSVC OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC"))' test/CMakeLists.txt; then
  echo "✓ test/CMakeLists.txt: Found correct MSVC detection logic"
  test_ok=true
else
  echo "✗ test/CMakeLists.txt: Missing correct MSVC detection logic"
  test_ok=false
fi

# Both files must have the fix for the test to pass
if [ "$main_ok" = true ] && [ "$test_ok" = true ]; then
  echo -e "\n✓ All fixes verified successfully"
  test_status=0
else
  echo -e "\n✗ Fix incomplete: Both CMakeLists.txt files must have the correct logic"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
