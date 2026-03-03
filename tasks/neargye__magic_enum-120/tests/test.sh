#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"
mkdir -p "test"
cp "/tests/test_flags.cpp" "test/test_flags.cpp"

# Patch test/CMakeLists.txt to remove -pedantic-errors (incompatible with emoji lexing)
sed -i 's/-pedantic-errors//g' test/CMakeLists.txt

# Clean and reconfigure build to pick up new test files and header changes
cd build
rm -rf CMakeCache.txt CMakeFiles test/CMakeFiles
CXXFLAGS="-fextended-identifiers -finput-charset=UTF-8" cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF
cmake --build . --target test-cpp17 --target test_flags-cpp17
build_status=$?

# If build fails, the test fails
if [ $build_status -ne 0 ]; then
  test_status=1
else
  # Run the specific test executables for both test.cpp and test_flags.cpp
  # The tests are built for multiple C++ standards, we'll run the C++17 version
  cd test
  ./test-cpp17
  test_status=$?

  # Only run test_flags if test.cpp passed
  if [ $test_status -eq 0 ]; then
    ./test_flags-cpp17
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
