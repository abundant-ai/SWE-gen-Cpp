#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-diagnostics.cpp" "test/src/unit-diagnostics.cpp"

# Rebuild the specific test binary
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON
ninja test-diagnostics

# Run the test binary for unit-diagnostics
./test/test-diagnostics
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
