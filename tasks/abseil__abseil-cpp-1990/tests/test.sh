#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "absl/container"
cp "/tests/absl/container/linked_hash_map_test.cc" "absl/container/linked_hash_map_test.cc"
cp "/tests/absl/container/linked_hash_set_test.cc" "absl/container/linked_hash_set_test.cc"

# Rebuild the specific tests after copying the new test files
cd build
cmake .. -DABSL_BUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
echo "=== Building test targets ==="
make absl_linked_hash_map_test absl_linked_hash_set_test -j$(nproc) 2>&1

# Run the specific test binaries
echo "=== Running linked_hash_map_test ==="
./bin/absl_linked_hash_map_test 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo "=== Running linked_hash_set_test ==="
  ./bin/absl_linked_hash_set_test 2>&1
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
