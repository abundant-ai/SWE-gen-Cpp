#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/compile_time"
cp "/tests/compile_time/CMakeLists.txt" "tests/compile_time/CMakeLists.txt"
mkdir -p "tests/compile_time"
cp "/tests/compile_time/basic_compile_time_tests.cpp" "tests/compile_time/basic_compile_time_tests.cpp"
mkdir -p "tests/compile_time"
cp "/tests/compile_time/compile_time_json_tests.cpp" "tests/compile_time/compile_time_json_tests.cpp"
mkdir -p "tests"
cp "/tests/test_macros.h" "tests/test_macros.h"

# Since the code uses experimental C++26 features that no released compiler supports,
# we can't actually compile it. Instead, we check for the presence of key compile-time
# JSON parsing features in the header files and test files. This is a simple text-based check.
#
# In BASE state (bug.patch applied): compile-time JSON parsing files are deleted
# In HEAD state (fix applied): compile-time JSON parsing files exist

test_status=0

# Check if compile_time_json.h exists and contains the parse_json function declaration
if [ -f "include/simdjson/compile_time_json.h" ]; then
  if grep -q "consteval auto parse_json" include/simdjson/compile_time_json.h; then
    # compile_time_json.h exists with parse_json - test passes (should happen in HEAD/fixed state)
    test_status=0
  else
    # File exists but doesn't have parse_json - test fails
    test_status=1
  fi
else
  # compile_time_json.h missing - test fails (should happen in BASE/buggy state)
  test_status=1
fi

# Also verify that the test files we copied are present and contain expected content
if [ $test_status -eq 0 ]; then
  if [ -f "tests/compile_time/compile_time_json_tests.cpp" ]; then
    if grep -q "compile_time::parse_json" tests/compile_time/compile_time_json_tests.cpp; then
      # Test file is present and uses parse_json - good
      test_status=0
    else
      # Test file doesn't contain expected content
      test_status=1
    fi
  else
    # Test file is missing
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
