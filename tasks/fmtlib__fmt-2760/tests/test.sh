#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/module-test.cc" "test/module-test.cc"

test_status=0

# Test that the fix properly deprecated make_args_checked and replaced its usage
# with make_format_args in formatting headers

# Check if make_args_checked is marked as FMT_DEPRECATED
echo "Checking if make_args_checked is properly deprecated..."
if grep -q "FMT_DEPRECATED.*make_args_checked" include/fmt/format.h; then
    echo "PASS: make_args_checked is marked as FMT_DEPRECATED"
else
    echo "FAIL: make_args_checked is NOT marked as FMT_DEPRECATED"
    test_status=1
fi

# Check that color.h, ostream.h, and xchar.h use make_format_args instead of make_args_checked
if grep -q "make_args_checked" include/fmt/color.h || \
   grep -q "make_args_checked" include/fmt/ostream.h || \
   grep -q "make_args_checked" include/fmt/xchar.h; then
    echo "FAIL: make_args_checked is still used in headers"
    test_status=1
else
    echo "PASS: make_args_checked is not used in headers"
fi

# Build the library to ensure it compiles
cd build
echo "Building fmt library..."
if ! make fmt 2>&1; then
    echo "FAIL: fmt library build failed"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
