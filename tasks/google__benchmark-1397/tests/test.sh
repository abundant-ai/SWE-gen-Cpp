#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/spec_arg_verbosity_test.cc" "test/spec_arg_verbosity_test.cc"

# Rebuild the test to pick up the updated test file
echo "Rebuilding spec_arg_verbosity_test..."
if cmake --build build --target spec_arg_verbosity_test --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ spec_arg_verbosity_test rebuild succeeded"
else
  echo "✗ spec_arg_verbosity_test rebuild failed"
  cat /tmp/build.log | tail -50
  test_status=1
  if [ $test_status -eq 0 ]; then
    echo 1 > /logs/verifier/reward.txt
  else
    echo 0 > /logs/verifier/reward.txt
  fi
  exit "$test_status"
fi

# Run the specific GoogleTest with required argument
echo "Running spec_arg_verbosity_test..."
./build/test/spec_arg_verbosity_test --v=42
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
