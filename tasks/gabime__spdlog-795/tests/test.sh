#!/bin/bash

cd /app/src

# Copy fixed test file from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_async.cpp" "tests/test_async.cpp"

# Rebuild with updated test file
cd build
cmake .. -DSPDLOG_BUILD_TESTS=ON -DSPDLOG_BUILD_EXAMPLES=OFF -DSPDLOG_BUILD_BENCH=OFF 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

make -j2 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the unit tests (executable is in tests subdirectory)
./tests/spdlog-utests 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
