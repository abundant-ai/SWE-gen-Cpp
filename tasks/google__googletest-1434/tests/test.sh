#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googletest/test"
cp "/tests/googletest/test/gtest-printers_test.cc" "googletest/test/gtest-printers_test.cc"

# Rebuild in the existing build directory
cd build

# Remove test executables to force rebuild
rm -f googlemock/gtest/gtest-printers_test

# Rebuild the specific test targets
make -j4 gtest-printers_test 2>&1

# Run the tests
./googlemock/gtest/gtest-printers_test 2>&1

# If we got here, compilation and tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
