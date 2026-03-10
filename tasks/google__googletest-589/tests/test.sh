#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock_test.cc" "googlemock/test/gmock_test.cc"

# Rebuild with autotools
cd googlemock

# Reconfigure and rebuild
autoreconf -fvi 2>&1
./configure 2>&1
make -j4 2>&1

# Run the specific test
make check 2>&1

# If we got here, build and tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
