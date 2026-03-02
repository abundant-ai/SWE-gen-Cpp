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

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild the specific tests
cd build
cmake ..
make chrono-test

# Run the specific tests (binaries are in bin/ directory)
./bin/chrono-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
