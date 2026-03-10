#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
mkdir -p "test"
cp "/tests/test.cc" "test/test.cc"
mkdir -p "test"
cp "/tests/test_thread_pool.cc" "test/test_thread_pool.cc"
mkdir -p "test"
cp "/tests/test_websocket_heartbeat.cc" "test/test_websocket_heartbeat.cc"

# Build and run the specific test binaries for this PR
cd /app/src/test
make test_thread_pool test_websocket_heartbeat && \
  LSAN_OPTIONS=suppressions=lsan_suppressions.txt ./test_thread_pool && \
  LSAN_OPTIONS=suppressions=lsan_suppressions.txt ./test_websocket_heartbeat
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
