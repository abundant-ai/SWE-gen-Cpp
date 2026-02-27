#!/bin/bash

cd /app/src

# Set CTest output to be verbose on failure
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/test_peer_disconnect.cpp" "tests/test_peer_disconnect.cpp"

# Rebuild the test in build directory with updated source files
cd build && cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON && make test_peer_disconnect -j$(nproc)

# Run only the specific test for this PR
ctest -R test_peer_disconnect -V
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
