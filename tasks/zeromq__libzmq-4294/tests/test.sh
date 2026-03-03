#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/test_xsub_verbose.cpp" "tests/test_xsub_verbose.cpp"

# Rebuild with the updated test files
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_xsub_verbose

# Run the specific test
./bin/test_xsub_verbose
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
