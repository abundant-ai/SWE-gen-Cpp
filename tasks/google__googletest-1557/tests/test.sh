#!/bin/bash

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-nice-strict_test.cc" "googlemock/test/gmock-nice-strict_test.cc"

# Rebuild the specific test files after copying them from /tests
cd build

# Reconfigure cmake to pick up the tests that were added back by fix.patch
# With the fixed code (inline constructors), CFI should pass
cmake -Dgtest_build_samples=ON \
      -Dgtest_build_tests=ON \
      -Dgmock_build_tests=ON \
      -DCMAKE_CXX_FLAGS="-flto -fsanitize=cfi -fvisibility=hidden" \
      -DCMAKE_EXE_LINKER_FLAGS="-flto -fsanitize=cfi" \
      .. && \
make -j4 gmock-nice-strict_test

# Run the specific test executables
./googlemock/gmock-nice-strict_test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
