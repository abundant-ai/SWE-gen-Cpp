#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Test the SIMDJSON_JUST_LIBRARY option
# In the BUGGY state: singleheader subdirectory is added even with SIMDJSON_JUST_LIBRARY=ON
# In the FIXED state: singleheader subdirectory is NOT added with SIMDJSON_JUST_LIBRARY=ON

# Clean and reconfigure with SIMDJSON_JUST_LIBRARY=ON
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_JUST_LIBRARY=ON -B build

# Check if amalgamate_demo target exists
# In BUGGY state: target WILL exist (because singleheader/ is added)
# In FIXED state: target will NOT exist (because singleheader/ is skipped)
if cmake --build build --target amalgamate_demo 2>/dev/null; then
    # Target exists - this is BUGGY behavior
    test_status=1
else
    # Target doesn't exist - this is FIXED behavior
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
