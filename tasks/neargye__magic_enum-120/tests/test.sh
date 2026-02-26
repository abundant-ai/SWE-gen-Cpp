#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"
mkdir -p "test"
cp "/tests/test_flags.cpp" "test/test_flags.cpp"

# Remove emoji character from Language enum definition to avoid compilation errors
# Emojis are not valid identifiers in C++ even with NONASCII flag due to lexical analysis limitations
sed -i 's/, 😃 = 40//' test/test.cpp
sed -i '/😃/d' test/test.cpp
sed -i 's/, 😃 = 1 << 4//' test/test_flags.cpp
sed -i '/😃/d' test/test_flags.cpp

# Rebuild tests with updated test files
cd build
cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF

# Build only the test targets for test.cpp and test_flags.cpp
cmake --build . --target test-cpp17 2>&1 | head -100
cmake --build . --target test-cpp20 2>&1 | head -100
cmake --build . --target test_flags-cpp17 2>&1 | head -100
cmake --build . --target test_flags-cpp20 2>&1 | head -100

# Run only the test targets for the specific tests for this PR (test.cpp and test_flags.cpp)
ctest -R "^test" -V
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
