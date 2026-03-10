#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_misc.cpp" "tests/test_misc.cpp"

# Build and run tests using CMake
mkdir -p build
cd build
cmake -DSPDLOG_BUILD_TESTS=ON .. 2>&1 || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Build the test executable
cmake --build . --target spdlog-utests 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run tests from test_misc.cpp
# Catch2 allows filtering tests - we run all tests from the test file using their tags
./tests/spdlog-utests "[basic_logging],[log_levels],[convert_to_string_view],[convert_to_short_c_str],[convert_to_level_enum],[periodic_flush],[clone],[default logger],[windows utf],[os]" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
