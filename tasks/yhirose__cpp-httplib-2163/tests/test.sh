#!/bin/bash

cd /app/src

# Set environment variables for leak sanitizer
export LSAN_OPTIONS=suppressions=test/lsan_suppressions.txt

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cc" "test/test.cc"

# Build and run the specific test executable
cd test

# Build test.cc with all required libraries and flags
clang++ -o test -I.. -g -std=c++11 -I. -Wall -Wextra -Wtype-limits -Wconversion -Wshadow -DCPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO test.cc gtest/src/gtest-all.cc gtest/src/gtest_main.cc -Igtest -Igtest/include -DCPPHTTPLIB_OPENSSL_SUPPORT -lssl -lcrypto -DCPPHTTPLIB_ZLIB_SUPPORT -lz -DCPPHTTPLIB_BROTLI_SUPPORT -lbrotlicommon -lbrotlienc -lbrotlidec -DCPPHTTPLIB_ZSTD_SUPPORT -lzstd -lpthread -lcurl -lanl

# Run the test, excluding online tests that require external network access
./test --gtest_filter=-*_Online
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
