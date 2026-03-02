#!/bin/bash

cd /app/src

# Copy SSL test files from HEAD (tests/CMakeLists.txt is restored by fix.patch)
mkdir -p "tests/ssl"
cp "/tests/ssl/CMakeLists.txt" "tests/ssl/CMakeLists.txt"
cp "/tests/ssl/ssltest.cpp" "tests/ssl/ssltest.cpp"

# Clean and rebuild the SSL test executable to ensure all changes are picked up
cd build
rm -f tests/ssl/ssltest tests/ssl/CMakeFiles/ssltest.dir/ssltest.cpp.o
cmake .. -DCROW_BUILD_TESTS=ON -DCROW_ENABLE_SSL=ON
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build . --target ssltest --clean-first
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the ssltest executable with timeout - will fail in buggy state, succeed with fix
timeout 30 ./tests/ssl/ssltest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
