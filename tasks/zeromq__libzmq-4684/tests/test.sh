#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "builds/cmake/Modules"
cp "/tests/Findgssapi_krb5.cmake" "builds/cmake/Modules/Findgssapi_krb5.cmake"

# Reconfigure and rebuild to test the updated CMakeLists.txt with GSSAPI support
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON 2>&1 | tee cmake_output.txt

# Check if GSSAPI support was properly recognized
if grep -q "Using GSSAPI_KRB5" cmake_output.txt; then
  # GSSAPI support is enabled, build should succeed
  make -j$(nproc)
  test_status=$?
else
  # GSSAPI option not recognized (buggy state)
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
