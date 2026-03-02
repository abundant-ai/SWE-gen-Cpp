#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (test/CMakeLists.txt with FMT_IMPORT restored)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Check if the main CMakeLists.txt has FMT_EXPORT definition
# This is added by fix.patch and is required for proper DLL export/import on Windows
cd /app/src
if grep -q "FMT_EXPORT" CMakeLists.txt; then
  echo "Main CMakeLists.txt has FMT_EXPORT definition - test PASSED"
  test_status=0
else
  echo "Main CMakeLists.txt is missing FMT_EXPORT definition - test FAILED"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
