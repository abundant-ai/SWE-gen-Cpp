#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/fuzzing"
cp "/tests/fuzzing/README.md" "test/fuzzing/README.md"

# This PR changes the fuzzing macro from FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
# back to FMT_FUZZ, along with updating the CMakeLists.txt to define it.
# We verify that FMT_FUZZ guards are working by testing exception throwing.

# Configure with fuzzing enabled
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=20 \
    -DFMT_FUZZ=ON \
    -DFMT_TEST=ON

# Build the fmt library
cmake --build build --target fmt

# Create a test to verify FMT_FUZZ guards are active
# The guards throw exceptions when precision > 100000
cat > /tmp/test_fuzz_guard.cpp << 'EOF'
#include <fmt/format.h>
#include <iostream>
#include <stdexcept>

int main() {
    try {
        // This should throw an exception when FMT_FUZZ is active
        // because precision > 100000 triggers the guard
        std::string result = fmt::format("{:.200000f}", 3.14);
        std::cerr << "ERROR: Expected exception from FMT_FUZZ guard, but none was thrown" << std::endl;
        return 1;  // FAIL - guard not active
    } catch (const std::runtime_error& e) {
        std::string msg = e.what();
        if (msg.find("fuzz mode") != std::string::npos) {
            std::cout << "SUCCESS: FMT_FUZZ guard is active and threw expected exception" << std::endl;
            return 0;  // PASS - guard is working
        } else {
            std::cerr << "ERROR: Unexpected exception: " << msg << std::endl;
            return 1;  // FAIL - wrong exception
        }
    }
}
EOF

# Compile and run the test
g++ -std=c++20 -I include /tmp/test_fuzz_guard.cpp build/libfmt.a -o /tmp/test_fuzz_guard
/tmp/test_fuzz_guard
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
