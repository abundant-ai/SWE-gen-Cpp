#!/bin/bash

cd /app/src

# Copy the fixed version of tests/CMakeLists.txt from /tests
# This is necessary because Oracle applies the main fix.patch, which doesn't include tests/CMakeLists.txt
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Reconfigure CMake using CROW_FEATURES (the new API this PR implements)
rm -rf build
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_FEATURES="ssl;compression" \
    -G Ninja 2>&1; then
  echo "CMake configuration failed"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build all tests (including SSL tests if configured correctly)
if ! cmake --build build 2>&1; then
  echo "Build failed"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that SSL tests were actually built (not just the directory)
if [ ! -f "build/tests/ssl/ssltest" ]; then
  echo "SSL test executable (ssltest) not found - CMakeLists.txt not using CROW_FEATURES correctly"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run unittest
./build/tests/unittest 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
