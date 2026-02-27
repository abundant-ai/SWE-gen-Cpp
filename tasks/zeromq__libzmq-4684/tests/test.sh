#!/bin/bash

cd /app/src

# Set CTest output to be verbose on failure
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Check if the main CMakeLists.txt has GSSAPI support
# Oracle will have it (from fix.patch), NOP won't (still buggy)
if grep -q "option(WITH_GSSAPI_KRB5" CMakeLists.txt && \
   grep -q "find_package(\"gssapi_krb5\"" CMakeLists.txt; then
  # GSSAPI support is present in main CMakeLists.txt - this is correct
  test_status=0
else
  # GSSAPI support is missing - the fix wasn't fully applied
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
