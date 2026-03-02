#!/bin/bash

cd /app/src

# Set environment variable for UBSAN suppressions
export UBSAN_OPTIONS=print_stacktrace=1,suppressions=$(pwd)/test/src/UBSAN.supp

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/src"
cp "/tests/src/UBSAN.supp" "test/src/UBSAN.supp"

# Rebuild from scratch with fixed CMakeLists.txt and sanitizers enabled
rm -rf build
cmake -S . -B build -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=clang-14 -DCMAKE_CXX_COMPILER=clang++-14 -DJSON_Sanitizer=ON

# Build the parser test (one at a time to avoid OOM)
cmake --build build --target test-class_parser --parallel 1

# Run the "all" variant of the parser test which skips problematic tests by default
cd build
ctest -R "test-class_parser_all" --output-on-failure
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
