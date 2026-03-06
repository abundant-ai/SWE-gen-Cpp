#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Rebuild with the updated test files to test the fixed version
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build all tests to verify CMakeLists.txt is correct (this verifies polling_util files exist)
make -j$(nproc)
build_status=$?

if [ $build_status -ne 0 ]; then
    test_status=$build_status
else
    # Verify INSTALL file has correct content (the actual fix for PR #3150)
    cd /app/src
    if grep -q "ZeroMQ generally" INSTALL; then
        echo "FAIL: INSTALL still contains outdated stack size information"
        test_status=1
    else
        echo "PASS: INSTALL file is correct (outdated information removed)"
        test_status=0
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
