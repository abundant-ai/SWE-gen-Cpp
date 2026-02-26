#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/ostream-test.cc" "test/ostream-test.cc"
mkdir -p "test"
cp "/tests/xchar-test.cc" "test/xchar-test.cc"

# Reconfigure and rebuild to pick up test file changes
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=23 \
    -DFMT_TEST=ON
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build the specific test targets
cmake --build build --target format-test --parallel $(nproc)
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build build --target ostream-test --parallel $(nproc)
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build build --target xchar-test --parallel $(nproc)
if [ $? -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific test binaries
./build/bin/format-test
format_status=$?

./build/bin/ostream-test
ostream_status=$?

./build/bin/xchar-test
xchar_status=$?

# Check if all tests passed
if [ $format_status -eq 0 ] && [ $ostream_status -eq 0 ] && [ $xchar_status -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
