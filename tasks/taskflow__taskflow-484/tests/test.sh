#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "unittests"
cp "/tests/unittests/test_reduce.cpp" "unittests/test_reduce.cpp"

# Check if test_reduce is already in CMakeLists.txt (fix.patch adds it, bug.patch removes it)
if ! grep -q "test_reduce" unittests/CMakeLists.txt; then
  # Re-add test_reduce to CMakeLists.txt (needed for NOP path)
  sed -i '5i\  test_reduce' unittests/CMakeLists.txt
fi

# Reconfigure CMake now that the test file exists
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Remove old build artifacts for test_reduce to force rebuild
rm -f build/unittests/test_reduce build/unittests/CMakeFiles/test_reduce.dir/test_reduce.cpp.o

# Rebuild the test binary (this will fail on buggy code since task_wrapper doesn't exist)
cmake --build build --target test_reduce --parallel $(nproc)
build_status=$?

# If build failed, that means tests fail (reward=0)
if [ $build_status -ne 0 ]; then
  echo "Build failed - test cannot run (expected on buggy code)" >&2
  test_status=1
else
  # Run the specific test binary
  ./build/unittests/test_reduce
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
