#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# The test is to verify that the code properly guards stream-related functionality
# In the buggy state (BASE), the guards are removed, so sstream is always included
# In the fixed state (HEAD), the guards are present, so with FMT_NO_STREAM_LIBRARIES defined, it should not include sstream

# Check if format.h properly guards the sstream include
if grep -A2 "^#ifndef FMT_NO_STREAM_LIBRARIES" format.h | grep -q "# include <sstream>"; then
  echo "format.h properly guards sstream include with FMT_NO_STREAM_LIBRARIES - test PASSED"
  test_status=0
else
  # Check if sstream is included unconditionally (buggy state)
  if grep -q "^#include <sstream>" format.h; then
    echo "format.h includes sstream unconditionally (missing FMT_NO_STREAM_LIBRARIES guard) - test FAILED"
    test_status=1
  else
    echo "format.h has unexpected structure - test FAILED"
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
