#!/bin/bash

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

# Rebuild the specific test files after copying them from /tests
cd build

# Remove the test executables to force rebuild with new flags
rm -f googlemock/gmock-actions_test googlemock/gmock-matchers_test \
      googletest/googletest-param-test-test googletest/googletest-port-test

# Rebuild with -Wdeprecated -Werror to catch deprecated usage
cmake -DCMAKE_CXX_FLAGS="-std=c++11 -Wdeprecated -Werror" .. && \
make -j4 gmock-actions_test gmock-matchers_test googletest-param-test-test googletest-port-test

# Run the specific test executables
./googlemock/gmock-actions_test && \
./googlemock/gmock-matchers_test && \
./googletest/googletest-param-test-test && \
./googletest/googletest-port-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
