#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"

# Remove emoji character from Language enum definition to avoid compilation errors
# Emojis are not valid identifiers in C++ even with NONASCII flag due to lexical analysis limitations
sed -i 's/, 😃 = 40//' test/test.cpp
sed -i '/😃/d' test/test.cpp

# Patch Catch2 to fix MINSIGSTKSZ issue with newer glibc
sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' test/3rdparty/Catch2/catch.hpp

# Rebuild tests with updated test files
cd build
cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF

# Build only the test targets for test.cpp
cmake --build . --target magic_enum-cpp17.t 2>&1 | head -100
cmake --build . --target magic_enum-cpp20.t 2>&1 | head -100

# Run only the test targets for the specific tests for this PR (test.cpp)
ctest -R "magic_enum" -V
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
