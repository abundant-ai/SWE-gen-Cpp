#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/chrono-test.cc" "test/chrono-test.cc"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/.gitignore" "test/fuzzing/.gitignore"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/CMakeLists.txt" "test/fuzzing/CMakeLists.txt"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/README.md" "test/fuzzing/README.md"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/build.sh" "test/fuzzing/build.sh"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/chrono_duration.cpp" "test/fuzzing/chrono_duration.cpp"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/fuzzer_common.h" "test/fuzzing/fuzzer_common.h"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/main.cpp" "test/fuzzing/main.cpp"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/named_arg.cpp" "test/fuzzing/named_arg.cpp"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/one_arg.cpp" "test/fuzzing/one_arg.cpp"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/sprintf.cpp" "test/fuzzing/sprintf.cpp"
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/two_args.cpp" "test/fuzzing/two_args.cpp"

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=11 \
    -DFMT_TEST=ON 2>&1

# Build the specific test target (capture both stdout and stderr)
cmake --build build --target chrono-test --parallel $(nproc) 2>&1
build_status=$?

# If build failed, exit with error
if [ $build_status -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run the test
  ./build/bin/chrono-test
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
