#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-diagnostic-positions-only.cpp" "tests/src/unit-diagnostic-positions-only.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-diagnostic-positions.cpp" "tests/src/unit-diagnostic-positions.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-json_patch.cpp" "tests/src/unit-json_patch.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-json_pointer.cpp" "tests/src/unit-json_pointer.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-regression1.cpp" "tests/src/unit-regression1.cpp"

# Rebuild the test executables with the updated test files
cmake --build build --target test-diagnostic-positions-only_cpp11
cmake --build build --target test-diagnostic-positions_cpp11
cmake --build build --target test-json_patch_cpp11
cmake --build build --target test-json_pointer_cpp11
cmake --build build --target test-regression1_cpp11

# Run the specific test executables
build/tests/test-diagnostic-positions-only_cpp11 && \
build/tests/test-diagnostic-positions_cpp11 && \
build/tests/test-json_patch_cpp11 && \
build/tests/test-json_pointer_cpp11 && \
build/tests/test-regression1_cpp11
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
