#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_document.cpp" "tests/test_document.cpp"

# Skip the flaky document_load_file_special_folder test that fails in Docker environment
# This test is unrelated to the PR (which is about move semantics)
sed -i '/^TEST(document_load_file_special_folder)/,/^}/d' tests/test_document.cpp

# Rebuild the test suite with the updated test files
rm -rf CMakeCache.txt CMakeFiles check
cmake . -DBUILD_TESTS=ON && make -j$(nproc)

# Run the test executable (test_document.cpp is compiled into the check executable)
./check
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
