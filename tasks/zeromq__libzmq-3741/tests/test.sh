#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_xpub_manual.cpp" "tests/test_xpub_manual.cpp"

# Rebuild with the updated test files to test the fixed version
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build the tests
make -j$(nproc)
build_status=$?

if [ $build_status -ne 0 ]; then
    test_status=$build_status
else
    # Run the specific test
    ./bin/test_xpub_manual
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
