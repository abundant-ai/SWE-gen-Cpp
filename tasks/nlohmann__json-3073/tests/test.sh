#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"

# Check if the fix has been applied to the library code
# The fix adds from_json and to_json overloads for std::filesystem::path
if ! grep -q "void from_json(const BasicJsonType& j, std::filesystem::path& p)" include/nlohmann/detail/conversions/from_json.hpp; then
    # Fix not applied - this is the buggy BASE state
    echo "Fix not applied - missing std::filesystem::path support in from_json" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! grep -q "void to_json(BasicJsonType& j, const std::filesystem::path& p)" include/nlohmann/detail/conversions/to_json.hpp; then
    # Fix not applied - this is the buggy BASE state
    echo "Fix not applied - missing std::filesystem::path support in to_json" >&2
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
