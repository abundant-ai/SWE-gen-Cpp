#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand/compilation_failure_tests"
cp "/tests/ondemand/compilation_failure_tests/CMakeLists.txt" "tests/ondemand/compilation_failure_tests/CMakeLists.txt"
mkdir -p "tests/ondemand/compilation_failure_tests"
cp "/tests/ondemand/compilation_failure_tests/iterate_char_star.cpp" "tests/ondemand/compilation_failure_tests/iterate_char_star.cpp"
mkdir -p "tests/ondemand/compilation_failure_tests"
cp "/tests/ondemand/compilation_failure_tests/iterate_string_view.cpp" "tests/ondemand/compilation_failure_tests/iterate_string_view.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_parse_api_tests.cpp" "tests/ondemand/ondemand_parse_api_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_readme_examples.cpp" "tests/ondemand/ondemand_readme_examples.cpp"

# Reconfigure CMake to pick up the restored test files
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build

# Build and run the specific test targets for this PR
test_status=0

# Build the specific test executables related to ondemand parse API tests and readme examples
if ! cmake --build build --target ondemand_parse_api_tests -j=2; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_readme_examples -j=2; then
    test_status=1
  fi
fi

# Run the specific tests
if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_parse_api_tests$|^ondemand_readme_examples$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
