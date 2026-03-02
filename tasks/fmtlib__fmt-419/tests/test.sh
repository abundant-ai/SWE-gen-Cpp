#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/add-subdirectory-test"
cp "/tests/add-subdirectory-test/main.cc" "test/add-subdirectory-test/main.cc"
mkdir -p "test/find-package-test"
cp "/tests/find-package-test/main.cc" "test/find-package-test/main.cc"
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"

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

make format-impl-test
if [ $? -eq 0 ]; then
  ./bin/format-impl-test
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
