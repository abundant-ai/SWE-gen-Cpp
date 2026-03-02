#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-iterators2.cpp" "tests/src/unit-iterators2.cpp"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"
cp "/tests/src/unit-udt.cpp" "tests/src/unit-udt.cpp"

# The bug is that these test files have issues with NVHPC compiler:
# 1. unit-iterators2.cpp: missing explicit return type "-> std::string_view" in lambda
# 2. unit-regression2.cpp: implicit sign conversion warnings with -1 and -2
# 3. unit-udt.cpp: Evil constructor signature and missing test case
# 4. binary_writer.hpp: unreachable code warning (static_cast after throw)
#
# With GCC/Clang, both buggy and fixed versions compile and run fine.
# We check if the fixes are present to determine if we're in BASE or HEAD state.

# Check for fix 1: explicit return type in unit-iterators2.cpp
# Use -- to prevent -> from being interpreted as an option
if ! grep -q -- "-> std::string_view" tests/src/unit-iterators2.cpp; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check for fix 2: static_cast in unit-regression2.cpp (two occurrences)
if ! grep -q "static_cast<std::string::value_type>(-1)" tests/src/unit-regression2.cpp; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check for fix 3: const T& in unit-udt.cpp
if ! grep -q "Evil(const T& t)" tests/src/unit-udt.cpp; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# Check for fix 4: static_cast should be OUTSIDE the if block (after the closing brace)
# In BASE (buggy): static_cast is inside if block (after throw, unreachable)
# In HEAD (fixed): static_cast is outside if block (before return, reachable)
if grep -A2 "JSON_THROW.*BSON key cannot contain" include/nlohmann/detail/output/binary_writer.hpp | grep -q "static_cast<void>(j)"; then
    # static_cast is inside the if block (after throw) - this is the buggy version
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi
# Check that static_cast exists outside the if block (should be after the closing brace)
if ! grep -B2 "return.*1ul.*name.size()" include/nlohmann/detail/output/binary_writer.hpp | grep -q "static_cast<void>(j)"; then
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi

# All fixes are present - verify code compiles and tests pass
cmake -S . -B build_verify -DJSON_BuildTests=ON > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
cmake --build build_verify --target download_test_data > /dev/null 2>&1 || true
cmake --build build_verify --target test-iterators2_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
cmake --build build_verify --target test-regression2_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
cmake --build build_verify --target test-udt_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

# Run tests to verify they pass
./build_verify/tests/test-iterators2_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
./build_verify/tests/test-regression2_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
./build_verify/tests/test-udt_cpp11 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

echo 1 > /logs/verifier/reward.txt
exit 0
