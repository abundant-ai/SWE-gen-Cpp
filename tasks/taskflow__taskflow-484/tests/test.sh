#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "unittests"
cp "/tests/unittests/test_reduce.cpp" "unittests/test_reduce.cpp"

# Reconfigure CMake to pick up any changes
cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release

# Remove old build artifacts for test_reduce to force rebuild
rm -f build/unittests/test_reduce build/unittests/CMakeFiles/test_reduce.dir/test_reduce.cpp.o

# Rebuild the test binary
cmake --build build --target test_reduce --parallel $(nproc)
build_status=$?

# If build failed, that means tests fail (reward=0)
if [ $build_status -ne 0 ]; then
  echo "Build failed" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific test binary
./build/unittests/test_reduce
test_status=$?

if [ $test_status -eq 0 ]; then
  echo "Tests passed"
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo "Tests failed" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
