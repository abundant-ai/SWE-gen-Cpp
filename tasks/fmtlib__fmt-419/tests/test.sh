#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/add-subdirectory-test"
cp "/tests/add-subdirectory-test/main.cc" "test/add-subdirectory-test/main.cc"
mkdir -p "test/find-package-test"
cp "/tests/find-package-test/main.cc" "test/find-package-test/main.cc"
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"

# Clean build directory to avoid CMake cache issues
rm -rf build

# Reconfigure with the updated test files
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_STANDARD=14 \
    -DFMT_TEST=ON 2>&1

# Build the specific test target
cmake --build build --target format-impl-test --parallel $(nproc) 2>&1
build_status=$?

# If build failed, exit with error
if [ $build_status -ne 0 ]; then
  echo "Build failed"
  test_status=1
else
  # Run the format-impl-test
  ./build/bin/format-impl-test
  format_impl_status=$?

  # Run the find-package-test and add-subdirectory-test using CTest
  cd build
  ctest -R "find-package-test|add-subdirectory-test" --output-on-failure
  ctest_status=$?
  cd ..

  # Both must pass
  if [ $format_impl_status -eq 0 ] && [ $ctest_status -eq 0 ]; then
    test_status=0
  else
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
