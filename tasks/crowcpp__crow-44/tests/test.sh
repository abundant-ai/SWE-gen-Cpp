#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Clean and rebuild the unittest executable to ensure all changes are picked up
cd build
rm -f tests/unittest tests/unittest.o tests/CMakeFiles/unittest.dir/unittest.cpp.o
cmake .. -DCROW_BUILD_TESTS=ON -DCROW_ENABLE_SSL=ON
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build . --target unittest --clean-first
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the unittest executable with timeout - will fail in buggy state, succeed with fix
timeout 30 ./tests/unittest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
