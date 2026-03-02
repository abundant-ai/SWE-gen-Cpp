#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-class_parser.cpp" "test/src/unit-class_parser.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-items.cpp" "test/src/unit-items.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression1.cpp" "test/src/unit-regression1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-udt.cpp" "test/src/unit-udt.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-udt_macro.cpp" "test/src/unit-udt_macro.cpp"

# Rebuild the specific test binaries
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON
ninja test-class_parser test-conversions test-items test-regression1 test-regression2 test-udt test-udt_macro

# Run each test binary
./test/test-class_parser && \
./test/test-conversions && \
./test/test-items && \
./test/test-regression1 && \
./test/test-regression2 && \
./test/test-udt && \
./test/test-udt_macro
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
