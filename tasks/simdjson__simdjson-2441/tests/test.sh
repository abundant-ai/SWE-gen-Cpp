#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/ranges_test.cpp" "tests/dom/ranges_test.cpp"

# Rebuild with strict compiler flags and exceptions disabled
# In buggy state, this will cause compilation errors
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 \
    -DSIMDJSON_EXCEPTIONS=OFF \
    -DCMAKE_CXX_FLAGS="-Werror=unused-result" \
    -B build

# Build all targets first - will fail in buggy state due to compilation errors in ondemand code
# when exceptions are disabled
if ! cmake --build build -j=2; then
  test_status=1
else
  # If build succeeded, run the specific test executable
  ./build/tests/dom/ranges_test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
