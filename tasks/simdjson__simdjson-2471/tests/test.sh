#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/builder"
cp "/tests/builder/static_reflection_comprehensive_tests.cpp" "tests/builder/static_reflection_comprehensive_tests.cpp"

# This PR adds the extract_into feature for static reflection
# The test verifies that extract_into is present in both the header and implementation
# In BASE state (after bug.patch), extract_into is removed
# Oracle agent needs to add it back for tests to pass

# Check if extract_into method is declared in the header file
if grep -q "extract_into" include/simdjson/generic/ondemand/object.h 2>/dev/null; then
    echo "extract_into method declaration found in header"
else
    echo "extract_into method declaration not found in header - feature is missing"
    test_status=1
fi

# Check if extract_into implementation exists in the inline header
if grep -q "extract_into" include/simdjson/generic/ondemand/object-inl.h 2>/dev/null; then
    echo "extract_into method implementation found"
    test_status=0
else
    echo "extract_into method implementation not found - feature is missing"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
