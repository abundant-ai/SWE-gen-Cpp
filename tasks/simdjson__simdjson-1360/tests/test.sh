#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/CMakeLists.txt" "tests/ondemand/CMakeLists.txt"
mkdir -p "tests/ondemand/compilation_failure_tests"
cp "/tests/ondemand/compilation_failure_tests/CMakeLists.txt" "tests/ondemand/compilation_failure_tests/CMakeLists.txt"
mkdir -p "tests/ondemand/compilation_failure_tests"
cp "/tests/ondemand/compilation_failure_tests/iterate_temporary_buffer.cpp" "tests/ondemand/compilation_failure_tests/iterate_temporary_buffer.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_active_tests.cpp" "tests/ondemand/ondemand_active_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_compilation_tests.cpp" "tests/ondemand/ondemand_compilation_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_dom_api_tests.cpp" "tests/ondemand/ondemand_dom_api_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_error_tests.cpp" "tests/ondemand/ondemand_error_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_key_string_tests.cpp" "tests/ondemand/ondemand_key_string_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_number_tests.cpp" "tests/ondemand/ondemand_number_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_ordering_tests.cpp" "tests/ondemand/ondemand_ordering_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_parse_api_tests.cpp" "tests/ondemand/ondemand_parse_api_tests.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_readme_examples.cpp" "tests/ondemand/ondemand_readme_examples.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_twitter_tests.cpp" "tests/ondemand/ondemand_twitter_tests.cpp"

# Reconfigure CMake to pick up the restored test files
# Force-define SIMDJSON_DEVELOPMENT_CHECKS via compiler flags since the buggy state renamed it to SIMDJSON_ONDEMAND_SAFETY_RAILS
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -DCMAKE_CXX_FLAGS="-DSIMDJSON_DEVELOPMENT_CHECKS" -B build

# Build and run the specific test targets for this PR
test_status=0

# Build the specific test executables for ondemand tests
if ! cmake --build build --target ondemand_active_tests -j=2; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_compilation_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_dom_api_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_error_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_key_string_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_number_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_ordering_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_parse_api_tests -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_readme_examples -j=2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! cmake --build build --target ondemand_twitter_tests -j=2; then
    test_status=1
  fi
fi

# Run the specific tests
if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_active_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_compilation_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_dom_api_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_error_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_key_string_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_number_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_ordering_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_parse_api_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_readme_examples$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  if ! timeout 60 ctest --test-dir build --output-on-failure -R "^ondemand_twitter_tests$" -j2; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
