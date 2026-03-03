#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/AssemblyTests.cmake" "test/AssemblyTests.cmake"

# The bug.patch removes find_package(Python3) from CMakeLists.txt and changes
# AssemblyTests.cmake to not use ${Python3_EXECUTABLE}.
# The fix restores find_package(Python3) and ${Python3_EXECUTABLE} usage.

# Test 1: Check that CMakeLists.txt has find_package(Python3)
if ! grep -q "find_package(Python3" CMakeLists.txt; then
  echo "FAIL: CMakeLists.txt missing find_package(Python3)"
  test_status=1
elif ! grep -q "Python3_EXECUTABLE" test/AssemblyTests.cmake; then
  # Test 2: Check that AssemblyTests.cmake uses Python3_EXECUTABLE
  echo "FAIL: AssemblyTests.cmake missing Python3_EXECUTABLE reference"
  test_status=1
elif ! grep -q "^#!/usr/bin/env python3" tools/strip_asm.py; then
  # Test 3: Check that strip_asm.py has correct shebang
  echo "FAIL: tools/strip_asm.py has wrong shebang (should be #!/usr/bin/env python3)"
  test_status=1
else
  # All checks passed - now verify it actually works by configuring CMake
  rm -rf /tmp/cmake_test
  mkdir -p /tmp/cmake_test
  if cmake -S /app/src -B /tmp/cmake_test \
      -DCMAKE_BUILD_TYPE=Debug \
      -DBENCHMARK_ENABLE_TESTING=ON 2>&1 | tee /tmp/cmake_log.txt; then
    # Check that Python3 was found
    if grep -q "Found Python3:" /tmp/cmake_log.txt; then
      echo "SUCCESS: All fixes applied correctly and CMake finds Python3"
      test_status=0
    else
      echo "FAIL: CMake configuration succeeded but Python3 was not found"
      test_status=1
    fi
  else
    echo "FAIL: CMake configuration failed"
    cat /tmp/cmake_log.txt
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
