#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"

# Comment out the problematic string_view implicit conversion test (around line 614-615)
# This test doesn't compile with Clang + newer libstdc++ due to explicit string_view exclusion in the library
# It's unrelated to PR #1555 which is about get_to overwriting container values
# We need to comment out both the declaration and the CHECK that follows it
sed -i '/^[[:space:]]*std::string_view s = j;/,+1 s/^/\/\/ /' test/src/unit-conversions.cpp

# Build the specific test using CMake
cmake --build build --target test-conversions
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
