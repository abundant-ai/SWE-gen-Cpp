#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Set environment variables for CTest
export CTEST_OUTPUT_ON_FAILURE=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-actions_test.cc" "googlemock/test/gmock-actions_test.cc"
mkdir -p "googlemock/test"
cp "/tests/googlemock/test/gmock-matchers_test.cc" "googlemock/test/gmock-matchers_test.cc"
mkdir -p "googletest/test"
cp "/tests/googletest/test/googletest-param-test-test.cc" "googletest/test/googletest-param-test-test.cc"
mkdir -p "googletest/test"
cp "/tests/googletest/test/googletest-port-test.cc" "googletest/test/googletest-port-test.cc"

# Rebuild in the existing build directory (faster than rebuilding from scratch)
cd build

# Remove test executables to force rebuild
rm -f googlemock/gmock-actions_test
rm -f googlemock/gmock-matchers_test
rm -f googletest/googletest-param-test-test
rm -f googletest/googletest-port-test

# Reconfigure with -Wdeprecated and turn deprecated warnings into errors
cmake -DCMAKE_CXX_FLAGS="-std=c++11 -Wdeprecated -Werror=deprecated" .. 2>&1

# Build only the specific test targets
make -j4 gmock-actions_test gmock-matchers_test googletest-param-test-test googletest-port-test 2>&1

# Run the specific test executables
./googlemock/gmock-actions_test 2>&1
./googlemock/gmock-matchers_test 2>&1
./googletest/googletest-param-test-test 2>&1
./googletest/googletest-port-test 2>&1

# If we got here, all tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
