#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "unittests"
cp "/tests/unittests/test_chunk_context.cpp" "unittests/test_chunk_context.cpp"

# Check if test_chunk_context is already in CMakeLists.txt (fix.patch adds it, bug.patch removes it)
if ! grep -q "test_chunk_context" unittests/CMakeLists.txt; then
  # Re-add test_chunk_context to CMakeLists.txt (needed for NOP path)
  sed -i '5i\  test_chunk_context' unittests/CMakeLists.txt
fi

# Reconfigure CMake now that the test file exists
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Remove old build artifacts for test_chunk_context to force rebuild
rm -f build/unittests/test_chunk_context build/unittests/CMakeFiles/test_chunk_context.dir/test_chunk_context.cpp.o

# Rebuild the test binary (this will fail on buggy code since task_wrapper doesn't exist)
cmake --build build --target test_chunk_context --parallel $(nproc)
build_status=$?

# If build failed, that means tests fail (reward=0)
if [ $build_status -ne 0 ]; then
  echo "Build failed - test cannot run (expected on buggy code)" >&2
  test_status=1
else
  # Run the specific test binary
  ./build/unittests/test_chunk_context
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
