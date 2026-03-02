#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test"
cp "/tests/include_httplib.cc" "test/include_httplib.cc"

# This PR is about enabling the ability to split httplib.h into separate compilation units
# The fixed version includes forward declarations and allows include_httplib.cc to be used
# Check if httplib.h contains the forward declarations section that was added
if grep -q "Forward declarations and types that will be part of the .h file if split into" httplib.h && \
   grep -q "std::pair<std::string, std::string> make_range_header(Ranges ranges);" httplib.h && \
   grep -q "namespace detail {" httplib.h | head -1; then
    # Fixed version: has the forward declarations for split compilation
    test_status=0
else
    # Buggy version: missing the forward declarations
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
