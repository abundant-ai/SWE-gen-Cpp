#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/unittest.cpp" "tests/unittest.cpp"

# Fix catch.hpp compatibility with modern glibc (old catch version doesn't support dynamic MINSIGSTKSZ)
sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' tests/catch.hpp
sed -i 's/char FatalConditionHandler::altStackMem\[sigStackSize\] = {};/char FatalConditionHandler::altStackMem[32768] = {};/' tests/catch.hpp

# Reconfigure CMake with the updated test files
rm -rf build
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROW_BUILD_TESTS=ON \
    -DCROW_BUILD_EXAMPLES=OFF \
    -DCROW_ENABLE_SSL=ON \
    -DCROW_ENABLE_COMPRESSION=ON \
    -G Ninja 2>&1; then
  echo "CMake configuration failed"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build and run the unittest executable
if ! cmake --build build --target unittest 2>&1; then
  echo "Build failed - unittest did not build successfully"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the unittest executable (with timeout since some tests may hang in buggy state)
timeout_duration=300
if timeout $timeout_duration ./build/tests/unittest 2>&1; then
  # Tests passed
  echo "Tests passed successfully"
  test_status=0
else
  exit_code=$?
  if [ $exit_code -eq 124 ]; then
    # Timeout occurred - treat as test failure
    echo "Tests timed out after ${timeout_duration}s (likely due to buggy code causing hang)"
    test_status=1
  else
    # Tests failed
    echo "Tests failed with exit code $exit_code"
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
