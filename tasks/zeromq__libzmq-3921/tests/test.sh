#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/fuzzer_corpora"
cp "/tests/fuzzer_corpora/test_bind_fuzzer.txt" "tests/fuzzer_corpora/test_bind_fuzzer.txt"
mkdir -p "tests"
cp "/tests/test_bind_fuzzer.cpp" "tests/test_bind_fuzzer.cpp"

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build
cd build
cmake .. -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_bind_fuzzer

# Run the specific test from /app/src (not from build dir) so relative paths work
cd /app/src
./build/bin/test_bind_fuzzer
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
