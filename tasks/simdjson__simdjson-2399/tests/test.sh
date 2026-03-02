#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/builder"
cp "/tests/builder/static_reflection_builder_tests.cpp" "tests/builder/static_reflection_builder_tests.cpp"
cp "/tests/builder/static_reflection_comprehensive_tests.cpp" "tests/builder/static_reflection_comprehensive_tests.cpp"
cp "/tests/builder/static_reflection_edge_cases_tests.cpp" "tests/builder/static_reflection_edge_cases_tests.cpp"

# Rebuild the specific test executables with the updated test files
# Build will fail in buggy state due to compilation errors when tests use missing features
if ! cmake --build build --target static_reflection_builder_tests static_reflection_comprehensive_tests static_reflection_edge_cases_tests; then
  test_status=1
else
  # If build succeeded, run the specific test executables
  ./build/tests/builder/static_reflection_builder_tests && \
  ./build/tests/builder/static_reflection_comprehensive_tests && \
  ./build/tests/builder/static_reflection_edge_cases_tests
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
