#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test_containers.cpp" "test/test_containers.cpp"

# Patch Catch2 to fix MINSIGSTKSZ issue with newer glibc
sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static const std::size_t sigStackSize = 32768;/' test/3rdparty/Catch2/catch.hpp

# Rebuild tests with updated test files
cd build
cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF

# Build only the test targets for test_containers.cpp
cmake --build . --target test_containers-cpp17 2>&1 | head -100
cmake --build . --target test_containers-cpp20 2>&1 | head -100

# Run only the test targets for the specific test for this PR (test_containers.cpp)
ctest -R "^test_containers-(cpp17|cpp20)$" -V
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
