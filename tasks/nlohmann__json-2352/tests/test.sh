#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-allocator.cpp" "test/src/unit-allocator.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_const_iterator.cpp" "test/src/unit-class_const_iterator.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_iterator.cpp" "test/src/unit-class_iterator.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_lexer.cpp" "test/src/unit-class_lexer.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-class_parser.cpp" "test/src/unit-class_parser.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-constructor1.cpp" "test/src/unit-constructor1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-convenience.cpp" "test/src/unit-convenience.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-conversions.cpp" "test/src/unit-conversions.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-iterators1.cpp" "test/src/unit-iterators1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-json_pointer.cpp" "test/src/unit-json_pointer.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression1.cpp" "test/src/unit-regression1.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-regression2.cpp" "test/src/unit-regression2.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-unicode.cpp" "test/src/unit-unicode.cpp"

# Rebuild the specific test binaries
cd build
cmake -S .. -B . -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 -DJSON_CI=ON

# Build test binaries for each test file (serial to avoid OOM)
ninja -j1 test-allocator test-class_const_iterator test-class_iterator test-class_lexer test-class_parser test-constructor1 test-convenience test-conversions test-iterators1 test-json_pointer test-regression1 test-regression2 test-unicode

# Run the test binaries
./test/test-allocator && \
./test/test-class_const_iterator && \
./test/test-class_iterator && \
./test/test-class_lexer && \
./test/test-class_parser && \
./test/test-constructor1 && \
./test/test-convenience && \
./test/test-conversions && \
./test/test-iterators1 && \
./test/test-json_pointer && \
./test/test-regression1 && \
./test/test-regression2 && \
./test/test-unicode
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
