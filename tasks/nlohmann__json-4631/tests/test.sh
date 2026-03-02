#!/bin/bash

cd /app/src

# Check fix 1: MSVC C++17 version check should use 19.10, not 19.1
if ! grep -q "CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.10" tests/CMakeLists.txt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check fix 2: MSVC C++20 version check for 19.20 should be present
if ! grep -q "CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.20" tests/CMakeLists.txt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check fix 3: Clang 3.5 check should be present
if ! grep -q "CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.5" tests/CMakeLists.txt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Check fix 4: GCC 7.0 check should be present
if ! grep -q "CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.0" tests/CMakeLists.txt; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify the build still works
cmake -S . -B build_verify -DJSON_BuildTests=ON > /dev/null 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
