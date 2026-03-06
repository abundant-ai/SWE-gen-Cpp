#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_ws_transport.cpp" "tests/test_ws_transport.cpp"

# Add test_ws_transport to CMakeLists.txt if not already present
if ! grep -q "test_ws_transport" tests/CMakeLists.txt; then
    # Find the line number of test_radio_dish and add test_ws_transport after it
    line_num=$(grep -n "test_radio_dish" tests/CMakeLists.txt | head -1 | cut -d: -f1)
    if [ -n "$line_num" ]; then
        sed -i "${line_num}a\\    test_ws_transport" tests/CMakeLists.txt
    fi
fi

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_ws_transport

# Run the specific test from /app/src (not from build dir) so relative paths work
cd /app/src
./build/bin/test_ws_transport
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
