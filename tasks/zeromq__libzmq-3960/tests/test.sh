#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/test_reconnect_options.cpp" "tests/test_reconnect_options.cpp"
mkdir -p "tests"
cp "/tests/testutil_monitoring.cpp" "tests/testutil_monitoring.cpp"
mkdir -p "tests"
cp "/tests/testutil_monitoring.hpp" "tests/testutil_monitoring.hpp"

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build && cd build
cmake .. -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_reconnect_options

# Run the specific test
./bin/test_reconnect_options
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
