#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the specific test for this PR
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++

make ostream-test
if [ $? -eq 0 ]; then
  ./bin/ostream-test
  test_status=$?
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
