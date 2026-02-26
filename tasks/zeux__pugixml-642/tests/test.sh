#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/autotest-appveyor.ps1" "tests/autotest-appveyor.ps1"

# The actual test is to verify the CMake configuration
# With the fix: CMAKE should default to C++17 when supported
# Without the fix (bug.patch applied): CMAKE defaults to C++11

# Configure with CMake and check what C++ standard is used
mkdir -p build_test
cd build_test

echo "# Configuring with CMake (no explicit C++ standard)"
cmake .. -DPUGIXML_BUILD_TESTS=ON 2>&1 | tee cmake_output.txt

echo "# Checking CMakeLists.txt for C++ standard logic:"
grep -A5 "CMAKE_CXX_STANDARD_REQUIRED" ../CMakeLists.txt || echo "# No CMAKE_CXX_STANDARD_REQUIRED logic found"

# CMAKE_CXX_STANDARD might not be in the cache since it's set without CACHE keyword
# Check the build flags in compile_commands.json or build.make files
echo "# Checking for actual compiler flags:"

# Try to build and capture the actual compile command
cmake --build . --verbose 2>&1 | tee build_output.txt | head -50

# Extract the actual C++ standard from compiler flags
if grep -q "\-std=c++17\|\-std=gnu++17" build_output.txt; then
    echo "# C++17 flag detected in build (FIX is applied)"
    test_status=0
elif grep -q "\-std=c++11\|\-std=gnu++11" build_output.txt; then
    echo "# C++11 flag detected in build (BUG is present)"
    test_status=1
elif grep -q "\-std=c++14\|\-std=gnu++14" build_output.txt; then
    echo "# C++14 flag detected (unexpected)"
    test_status=1
else
    # No explicit -std flag means compiler default (likely C++11 or C++14)
    echo "# No explicit -std flag found, checking CMakeLists.txt logic"
    # Check if the fix logic is present
    if grep -q "set(CMAKE_CXX_STANDARD 17)" ../CMakeLists.txt; then
        echo "# CMakeLists.txt has C++17 logic but it wasn't applied - possible CMake version issue"
        test_status=1
    else
        echo "# C++17 logic not found in CMakeLists.txt (BUG is present)"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
