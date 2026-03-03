#!/bin/bash

cd /app/src

# Rebuild to pick up any changes
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON
make -j$(nproc)

# The fix should remove unlicensed code (tweetnacl, zmq_proxy_steerable, etc.)
# Check that tweetnacl source files are NOT present in the build
test_status=1

# Check if tweetnacl files were removed
if [ ! -f ../src/tweetnacl.c ] && [ ! -f ../src/tweetnacl.h ]; then
    echo "SUCCESS: tweetnacl files properly removed"
    test_status=0
else
    echo "FAIL: tweetnacl files still present"
    test_status=1
fi

# Also verify the library still builds
if [ $test_status -eq 0 ] && [ ! -f ./lib/libzmq.so ]; then
    echo "FAIL: libzmq.so not built"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
