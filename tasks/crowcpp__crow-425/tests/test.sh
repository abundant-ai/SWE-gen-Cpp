#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ssl"
cp "/tests/ssl/ssltest.cpp" "tests/ssl/ssltest.cpp"
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Rebuild with the updated test files
if ! cmake --build build --target unittest 2>&1; then
  echo "Build failed for unittest"
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
