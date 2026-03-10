#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-matchers_test.cc" "googlemock/test/gmock-matchers_test.cc"
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-spec-builders_test.cc" "googlemock/test/gmock-spec-builders_test.cc"

# Rebuild in the existing build directory
cd build

# Remove test executables to force rebuild
rm -f googlemock/gmock-matchers_test googlemock/gmock-spec-builders_test

# Rebuild the specific test targets
make -j4 gmock-matchers_test gmock-spec-builders_test 2>&1

# Run the tests
./googlemock/gmock-matchers_test 2>&1
./googlemock/gmock-spec-builders_test 2>&1

# If we got here, compilation and tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
