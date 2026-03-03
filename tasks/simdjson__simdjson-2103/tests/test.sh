#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/basictests.cpp" "tests/dom/basictests.cpp"

# Reconfigure CMake to pick up the restored test definitions from CMakeLists.txt
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the test executable
test_status=0

# Build basictests
if ! cmake --build build --target basictests -j=2; then
  test_status=1
# Run basictests
elif ! ./build/tests/dom/basictests; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
