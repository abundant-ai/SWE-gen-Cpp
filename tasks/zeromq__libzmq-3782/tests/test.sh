#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_ws_transport.cpp" "tests/test_ws_transport.cpp"

# Add test_ws_transport to CMakeLists.txt if not already present
cd tests
if ! grep -q "test_ws_transport" CMakeLists.txt; then
  # Add it to the ENABLE_DRAFTS section
  sed -i '/test_xpub_manual_last_value/a\    test_ws_transport' CMakeLists.txt
fi
cd ..

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build test_ws_transport
make -j$(nproc) test_ws_transport
test_status=$?

if [ $test_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $test_status
fi

# Run the test
cd /app/src
./build/bin/test_ws_transport
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
