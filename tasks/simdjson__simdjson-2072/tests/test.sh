#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/document_tests.cpp" "tests/dom/document_tests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executables
test_status=0

# Build document_tests
if ! cmake --build build --target document_tests -j=2; then
  test_status=1
# Run document_tests
elif ! ./build/tests/dom/document_tests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
