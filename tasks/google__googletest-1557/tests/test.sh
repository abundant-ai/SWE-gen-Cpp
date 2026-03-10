#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Copy HEAD test files from /tests (includes AllowLeak tests that fail with BASE's buggy implementation)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-nice-strict_test.cc" "googlemock/test/gmock-nice-strict_test.cc"

# Rebuild in the existing build directory
cd build

# Remove test executable to force rebuild
rm -f googlemock/gmock-nice-strict_test

# Rebuild the specific test target
make -j4 gmock-nice-strict_test 2>&1

# Run the test
./googlemock/gmock-nice-strict_test 2>&1

# If we got here, compilation and tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
