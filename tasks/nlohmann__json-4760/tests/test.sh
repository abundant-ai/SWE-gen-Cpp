#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-msgpack.cpp" "tests/src/unit-msgpack.cpp"

# The bug is that char_traits<std::byte> is missing, causing compilation failure
# on stricter standard libraries (AppleClang/Xcode 16.3+). However, GCC and
# libc++ 18 on Ubuntu are more permissive and don't fail compilation.
#
# To work around this, we check if the char_traits<std::byte> specialization
# exists in the code. If it doesn't exist (BASE state), we expect the build
# to potentially fail on strict platforms, so we return reward=0.
# If it exists (HEAD state), the code should work on all platforms, reward=1.

# Check if the char_traits<std::byte> specialization exists
if grep -q "char_traits<std::byte>" include/nlohmann/detail/meta/type_traits.hpp; then
    # Fix is present - build and run tests to verify they pass
    cmake -S . -B build_verify -DJSON_BuildTests=ON > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }
    cmake --build build_verify --target download_test_data > /dev/null 2>&1 || true
    cmake --build build_verify --target test-msgpack_cpp17 > /dev/null 2>&1 || { echo 0 > /logs/verifier/reward.txt; exit 1; }

    if ./build_verify/tests/test-msgpack_cpp17 > /dev/null 2>&1; then
        echo 1 > /logs/verifier/reward.txt
        exit 0
    else
        echo 0 > /logs/verifier/reward.txt
        exit 1
    fi
else
    # Fix is missing (BASE state) - this would fail on strict platforms
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi
