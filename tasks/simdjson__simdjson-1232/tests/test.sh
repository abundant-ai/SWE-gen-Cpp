#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_basictests.cpp" "tests/ondemand/ondemand_basictests.cpp"

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_ONDEMAND_SAFETY_RAILS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build the simdjson library
cmake --build build --target simdjson -j=2

# Build the specific test
cmake --build build --target ondemand_basictests -j=2

# Run the test
./build/tests/ondemand/ondemand_basictests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
