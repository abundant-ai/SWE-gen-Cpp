#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_ws_transport.cpp" "tests/test_ws_transport.cpp"

# Rebuild with the updated test files
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_ws_transport

# Run the specific test
./bin/test_ws_transport
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
