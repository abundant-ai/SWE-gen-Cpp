#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_ws_transport.cpp" "tests/test_ws_transport.cpp"
mkdir -p "tests"
cp "/tests/test_wss_transport.cpp" "tests/test_wss_transport.cpp"

# Rebuild with the updated test files to test the fixed version
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build and run the specific tests
make -j$(nproc)
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
