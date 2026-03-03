#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/basictests.cpp" "tests/basictests.cpp"
mkdir -p "tests"
cp "/tests/readme_examples.cpp" "tests/readme_examples.cpp"

# Clean build directory to ensure fresh build
rm -rf build

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_ONDEMAND_SAFETY_RAILS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build the simdjson library
cmake --build build --target simdjson -j=2

# Build and run both test binaries
cmake --build build --target basictests -j=2
cmake --build build --target readme_examples -j=2

# Run both tests
./build/tests/basictests
test_status_1=$?

./build/tests/readme_examples
test_status_2=$?

# Both tests must pass
if [ $test_status_1 -eq 0 ] && [ $test_status_2 -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
