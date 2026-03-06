#!/bin/bash

cd /app/src

# Add test_bind_ws_fuzzer to CMakeLists.txt so it gets built
cd tests
sed -i '/if(ZMQ_HAVE_WS)/a\  list(APPEND tests test_bind_ws_fuzzer)' CMakeLists.txt
cd ..

# Rebuild from scratch to ensure clean state
rm -rf build
mkdir -p build && cd build
cmake .. -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc) test_bind_ws_fuzzer

# Verify the fix by checking socket types used in test
# The fix changes ZMQ_SERVER/CLIENT (draft sockets) to ZMQ_DEALER (stable)
if grep -q "ZMQ_DEALER" ../tests/test_bind_ws_fuzzer.cpp; then
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
