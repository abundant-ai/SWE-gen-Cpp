#!/bin/bash

cd /app/src

# Set environment variables for leak sanitizer
export LSAN_OPTIONS=suppressions=test/lsan_suppressions.txt

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test"
cp "/tests/test.cc" "test/test.cc"
mkdir -p "test"
cp "/tests/test_thread_pool.cc" "test/test_thread_pool.cc"
mkdir -p "test"
cp "/tests/test_websocket_heartbeat.cc" "test/test_websocket_heartbeat.cc"

# Build and run the specific test executables
cd test

# Build test_thread_pool (no TLS needed) without ASAN to avoid false positives
clang++ -o test_thread_pool -I.. -g -std=c++11 -I. -Wall -Wextra -Wtype-limits -Wconversion -Wshadow -DCPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO test_thread_pool.cc gtest/src/gtest-all.cc gtest/src/gtest_main.cc -Igtest -Igtest/include -lpthread

# Build test_websocket_heartbeat (needs TLS) without ASAN to avoid false positives
clang++ -o test_websocket_heartbeat -I.. -g -std=c++11 -I. -Wall -Wextra -Wtype-limits -Wconversion -Wshadow -DCPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO test_websocket_heartbeat.cc gtest/src/gtest-all.cc gtest/src/gtest_main.cc -Igtest -Igtest/include -DCPPHTTPLIB_OPENSSL_SUPPORT -lssl -lcrypto -DCPPHTTPLIB_ZLIB_SUPPORT -lz -DCPPHTTPLIB_BROTLI_SUPPORT -lbrotlicommon -lbrotlienc -lbrotlidec -DCPPHTTPLIB_ZSTD_SUPPORT -lzstd -lpthread -lcurl -lanl

# Run the tests
./test_thread_pool
status1=$?

./test_websocket_heartbeat
status2=$?

# Both must pass
test_status=0
if [ $status1 -ne 0 ] || [ $status2 -ne 0 ]; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
