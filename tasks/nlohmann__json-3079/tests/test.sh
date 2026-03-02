#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Check if the fix has been applied to the library code
# The fix changes "ValueType ret{};" to "auto ret = ValueType();"
if ! grep -q "auto ret = ValueType();" include/nlohmann/json.hpp; then
    # Fix not applied - this is the buggy BASE state
    # On MSVC, this would fail to compile, but on GCC/Clang it compiles fine
    # We need to fail the test manually since the bug is MSVC-specific
    echo "Fix not applied - code still uses buggy 'ValueType ret{}' pattern" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild the test executable with the updated test file
if ! cmake --build build --target test-regression2; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executable for unit-regression2.cpp
./build/test/test-regression2
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
