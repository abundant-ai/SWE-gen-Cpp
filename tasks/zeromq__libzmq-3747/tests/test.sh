#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/testutil_security.cpp" "tests/testutil_security.cpp"

# testutil_security.cpp is a utility file, not a standalone test
# Just verify it compiles successfully as part of the build
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build the entire project to verify testutil_security.cpp compiles
make -j$(nproc)
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
