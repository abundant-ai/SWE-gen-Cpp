#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/multi_file"
cp "/tests/multi_file/CMakeLists.txt" "tests/multi_file/CMakeLists.txt"
mkdir -p "tests/multi_file"
cp "/tests/multi_file/main.cpp" "tests/multi_file/main.cpp"
mkdir -p "tests/multi_file"
cp "/tests/multi_file/secondary.cpp" "tests/multi_file/secondary.cpp"

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

# Build the multi_file test executable
# The test succeeds if the project links successfully (no ODR violation)
if ! cmake --build build --target test_multi_file 2>&1; then
  echo "Build failed - multi_file test did not link successfully (ODR violation likely)"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that the multi_file test executable was built and linked
if [ ! -f "build/tests/multi_file/test_multi_file" ]; then
  echo "Multi-file test executable not found - linking may have failed"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Success! The multi-file project built and linked without ODR violation
echo "Multi-file test built and linked successfully - no ODR violation"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
