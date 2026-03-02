#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_macros.h" "tests/test_macros.h"

# This PR adds the extract_from feature for static reflection
# The test verifies that extract_from is present in the code
# In BASE state (after bug.patch), extract_from is removed
# Oracle agent needs to add it back for tests to pass

# Check if extract_from function is defined in the header
if grep -q "extract_from" include/simdjson/generic/ondemand/json_builder.h 2>/dev/null; then
    echo "extract_from function found - feature is implemented"
    test_status=0
else
    echo "extract_from function not found - feature is missing"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
