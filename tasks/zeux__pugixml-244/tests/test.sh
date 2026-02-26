#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test.cpp" "tests/test.cpp"
mkdir -p "tests"
cp "/tests/test_dom_text.cpp" "tests/test_dom_text.cpp"
mkdir -p "tests"
cp "/tests/test_dom_traverse.cpp" "tests/test_dom_traverse.cpp"
mkdir -p "tests"
cp "/tests/test_xpath.cpp" "tests/test_xpath.cpp"

# Rebuild the test suite with the updated test files and strict warnings
rm -rf CMakeCache.txt CMakeFiles check
cmake . -DBUILD_TESTS=ON -DCMAKE_CXX_FLAGS="-Werror=double-promotion" && make -j$(nproc)

# Run the test executable (test.cpp contains the main test infrastructure, plus dom and xpath tests)
./check
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
