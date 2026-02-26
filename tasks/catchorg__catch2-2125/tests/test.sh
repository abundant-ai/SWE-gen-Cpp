#!/bin/bash

cd /app/src

# Copy HEAD source files and baselines from /tests (overwrites BASE state with fixed versions)
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
cp "/tests/SelfTest/Baselines/console.sw.approved.txt" "tests/SelfTest/Baselines/console.sw.approved.txt"
cp "/tests/SelfTest/Baselines/tap.sw.approved.txt" "tests/SelfTest/Baselines/tap.sw.approved.txt"
cp "/tests/SelfTest/Baselines/xml.sw.approved.txt" "tests/SelfTest/Baselines/xml.sw.approved.txt"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/String.tests.cpp" "tests/SelfTest/IntrospectiveTests/String.tests.cpp"
cp "/tests/SelfTest/IntrospectiveTests/Xml.tests.cpp" "tests/SelfTest/IntrospectiveTests/Xml.tests.cpp"

# Copy the fixed source files (benchmark stats with modern casts)
mkdir -p "src/catch2/benchmark/detail"
cp "/tests/catch2/benchmark/detail/catch_stats.cpp" "src/catch2/benchmark/detail/catch_stats.cpp"
cp "/tests/catch2/benchmark/detail/catch_stats.hpp" "src/catch2/benchmark/detail/catch_stats.hpp"

# Copy the fixed CMake file (re-enables -Wold-style-cast)
mkdir -p "CMake"
cp "/tests/CMake/MiscFunctions.cmake" "CMake/MiscFunctions.cmake"

# Reconfigure CMake to pick up the -Wold-style-cast flag
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja; then
    echo "CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild - this will FAIL in BASE state (old-style casts), PASS in HEAD state (modern casts)
if ! cmake --build build 2>&1; then
    echo "Build failed - old-style casts still present"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the StringRef tests to verify they pass with modern casts
if ! ./build/tests/SelfTest "[StringRef]"; then
    echo "StringRef tests failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
