#!/bin/bash
set -e

# Trap any error and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' EXIT

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock_test.cc" "googlemock/test/gmock_test.cc"

# Try to reconfigure and rebuild (this will fail if autotools config is broken)
cd googletest
autoreconf -fvi >/dev/null 2>&1
./configure >/dev/null 2>&1
make -j4 >/dev/null 2>&1

cd ../googlemock
autoreconf -fvi >/dev/null 2>&1
./configure >/dev/null 2>&1
make -j4 >/dev/null 2>&1

# Compile the test manually (gmock_test is not in the standard TESTS list)
g++ -std=c++11 -I../googletest/include -Iinclude -I. -I../googletest \
    -pthread test/gmock_test.cc lib/.libs/libgmock.a lib/.libs/libgmock_main.a ../googletest/lib/.libs/libgtest.a \
    -o test_gmock_test

# Run the test
./test_gmock_test

# If we got here, test passed
trap - EXIT  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
