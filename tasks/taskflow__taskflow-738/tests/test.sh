#!/bin/bash

cd /app/src

# Check if the library code has the MSVC warning fixes applied
# The fix includes changing "if (all)" to "if constexpr (all)" in nonblocking_notifier.hpp
has_fix=0
if grep -q "if constexpr (all)" taskflow/core/nonblocking_notifier.hpp; then
  has_fix=1
  echo "Library code has MSVC warning fixes"
else
  echo "Library code is buggy (missing 'if constexpr' fixes)"
fi

# Copy HEAD test files from /tests (overwrites BASE state with fixed test)
mkdir -p "unittests"
cp "/tests/unittests/test_exceptions.cpp" "unittests/test_exceptions.cpp"

# If library doesn't have the fix, tests should fail (reward=0)
if [ $has_fix -eq 0 ]; then
  echo "Library code is buggy - simulating MSVC /WX failure" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Reconfigure CMake to pick up any changes
cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release

# Remove old build artifacts for test_exceptions to force rebuild
rm -f build/unittests/test_exceptions build/unittests/CMakeFiles/test_exceptions.dir/test_exceptions.cpp.o

# Rebuild the test binary
cmake --build build --target test_exceptions --parallel $(nproc)
build_status=$?

# If build failed, that means tests fail (reward=0)
if [ $build_status -ne 0 ]; then
  echo "Build failed" >&2
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific test binary
./build/unittests/test_exceptions
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
