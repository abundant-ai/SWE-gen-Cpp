#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/test_proxy_steerable.cpp" "tests/test_proxy_steerable.cpp"

# Reconfigure and rebuild to include the test_proxy_steerable test
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc)

# Run the specific test
./bin/test_proxy_steerable
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
