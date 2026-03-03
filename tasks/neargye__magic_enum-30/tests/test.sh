#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"

# Patch test/CMakeLists.txt to remove -pedantic-errors (incompatible with emoji lexing)
sed -i 's/-pedantic-errors//g' test/CMakeLists.txt

# Patch Catch2 to fix MINSIGSTKSZ compilation error with modern glibc
sed -i 's/static constexpr std::size_t sigStackSize/static const std::size_t sigStackSize/' test/3rdparty/Catch2/catch.hpp
sed -i 's/char FatalConditionHandler::altStackMem\[sigStackSize\]/char FatalConditionHandler::altStackMem[1024 * 32]/' test/3rdparty/Catch2/catch.hpp

# Clean and reconfigure build to pick up new test files and header changes
cd build
rm -rf CMakeCache.txt CMakeFiles test/CMakeFiles
CXXFLAGS="-fextended-identifiers -finput-charset=UTF-8" cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=ON
cmake --build . --target magic_enum-cpp17.t
build_status=$?

# If build fails, the test fails
if [ $build_status -ne 0 ]; then
  test_status=1
else
  # Run the specific test executable for test.cpp
  # The tests are built for multiple C++ standards, we'll run the C++17 version
  cd test
  ./magic_enum-cpp17.t
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
