#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cc" "test/test.cc"

# Check if httplib.h contains the is_writable function in DataSink struct
# In the fixed version, is_writable should NOT be present as a member of DataSink
# In the buggy version, it WILL be present
if grep -q "std::function<bool()> is_writable;" httplib.h; then
    # Buggy version: has the unnecessary is_writable function
    test_status=1
else
    # Fixed version: is_writable has been removed
    # Build and run tests to ensure everything still works
    export LSAN_OPTIONS=suppressions=test/lsan_suppressions.txt
    cd test
    clang++ -o test -I.. -g -std=c++11 -I. -Wall -Wextra -Wtype-limits -Wconversion -Wshadow -DCPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO test.cc gtest/gtest-all.cc gtest/gtest_main.cc -Igtest -DCPPHTTPLIB_OPENSSL_SUPPORT -lssl -lcrypto -DCPPHTTPLIB_ZLIB_SUPPORT -lz -DCPPHTTPLIB_BROTLI_SUPPORT -lbrotlicommon -lbrotlienc -lbrotlidec -DCPPHTTPLIB_ZSTD_SUPPORT -lzstd -lpthread -lcurl -lanl

    ./test --gtest_filter=-*_Online
    test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
