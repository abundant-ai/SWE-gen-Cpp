#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/test.cpp" "test/test.cpp"

# Clean and reconfigure build to pick up new test file
cd build
rm -rf test/CMakeFiles/test-cpp17.dir
cmake .. -DMAGIC_ENUM_OPT_BUILD_TESTS=ON -DMAGIC_ENUM_OPT_ENABLE_NONASCII=OFF
cmake --build . --target test-cpp17
build_status=$?

# If build fails, the test fails
if [ $build_status -ne 0 ]; then
  test_status=1
else
  # Run the specific test executable for test.cpp
  # The test is built for multiple C++ standards, we'll run the C++17 version
  cd test
  ./test-cpp17
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
