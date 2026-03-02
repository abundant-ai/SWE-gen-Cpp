#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/Makefile" "tests/Makefile"
mkdir -p "tests"
cp "/tests/cond_logging.cpp" "tests/cond_logging.cpp"
mkdir -p "tests"
cp "/tests/errors.cpp" "tests/errors.cpp"
mkdir -p "tests"
cp "/tests/file_log.cpp" "tests/file_log.cpp"

# Build and run tests with printf style (STYLE=printf sets -DSPDLOG_FMT_PRINTF)
cd /app/src/tests
make rebuild STYLE=printf 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the tests binary
./tests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
