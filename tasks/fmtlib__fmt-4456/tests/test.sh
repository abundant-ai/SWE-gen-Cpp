#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/compile-test.cc" "test/compile-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Reconfigure CMake to pick up the new test file
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_TEST=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DFMT_PEDANTIC=ON \
    -DCMAKE_CXX_FLAGS="-I/usr/local/include/workaround -stdlib=libc++"

# Build the specific test target
cmake --build . --target compile-test
test_status=$?

if [ $test_status -eq 0 ]; then
  # Run the specific test and check if constexpr_format test ran
  test_output=$(./bin/compile-test 2>&1)
  test_status=$?
  echo "$test_output"

  # Verify that the constexpr_format test actually ran
  # This test should only exist with the fix applied (HEAD state)
  if [ $test_status -eq 0 ]; then
    if ! echo "$test_output" | grep -q "RUN.*compile_test.constexpr_format$"; then
      echo "ERROR: constexpr_format test did not run - FMT_USE_CONSTEXPR_STRING not enabled" >&2
      test_status=1
    fi
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
