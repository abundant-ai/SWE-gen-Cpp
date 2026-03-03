#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"
mkdir -p "test"
cp "/tests/map_test.cc" "test/map_test.cc"
mkdir -p "test"
cp "/tests/multiple_ranges_test.cc" "test/multiple_ranges_test.cc"
mkdir -p "test"
cp "/tests/options_test.cc" "test/options_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Rebuild the specific test targets with updated source files
# Exit immediately if build fails
if ! cmake --build build --target basic_test benchmark_test complexity_test fixture_test map_test multiple_ranges_test options_test reporter_output_test skip_with_error_test -j 1; then
    echo "Build failed - tests cannot be run" >&2
    test_status=1
else
    # Run only the specific tests for this PR
    cd build
    ctest -R "^(basic_test|benchmark_test|complexity_test|fixture_test|map_test|multiple_ranges_test|options_test|reporter_output_test|skip_with_error_test)$" --output-on-failure -V
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
