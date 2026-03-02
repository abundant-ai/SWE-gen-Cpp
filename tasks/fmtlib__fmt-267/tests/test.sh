#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test/add_subdirectory-test"
cp "/tests/add_subdirectory-test/CMakeLists.txt" "test/add_subdirectory-test/CMakeLists.txt"
mkdir -p "test/add_subdirectory-test"
cp "/tests/add_subdirectory-test/main.cpp" "test/add_subdirectory-test/main.cpp"
mkdir -p "test"
cp "/tests/assert-test.cc" "test/assert-test.cc"
mkdir -p "test/compile-test"
cp "/tests/compile-test/CMakeLists.txt" "test/compile-test/CMakeLists.txt"
mkdir -p "test/find-package-test"
cp "/tests/find-package-test/CMakeLists.txt" "test/find-package-test/CMakeLists.txt"
mkdir -p "test/find-package-test"
cp "/tests/find-package-test/main.cpp" "test/find-package-test/main.cpp"
mkdir -p "test"
cp "/tests/format-impl-test.cc" "test/format-impl-test.cc"
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"
mkdir -p "test"
cp "/tests/gtest-extra.h" "test/gtest-extra.h"
mkdir -p "test"
cp "/tests/header-only-test.cc" "test/header-only-test.cc"
mkdir -p "test"
cp "/tests/header-only-test2.cc" "test/header-only-test2.cc"
mkdir -p "test"
cp "/tests/macro-test.cc" "test/macro-test.cc"
mkdir -p "test"
cp "/tests/posix-mock-test.cc" "test/posix-mock-test.cc"
mkdir -p "test"
cp "/tests/posix-test.cc" "test/posix-test.cc"
mkdir -p "test"
cp "/tests/printf-test.cc" "test/printf-test.cc"
mkdir -p "test"
cp "/tests/util-test.cc" "test/util-test.cc"
mkdir -p "test"
cp "/tests/util.h" "test/util.h"

# Remove test/format file to avoid header collision with std::format
rm -f test/format

# Rebuild and run the compile tests (relevant to this PR)
cd build
rm -rf *

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DFMT_TEST=ON \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DFMT_PEDANTIC=ON

if [ $? -ne 0 ]; then
  test_status=1
else
  # Build the library first (needed for find-package-test)
  make cppformat
  if [ $? -ne 0 ]; then
    test_status=1
  else
    # Run the compile-test and other CMake integration tests
    ctest -R "compile-test|add_subdirectory-test|find-package-test" --output-on-failure
    test_status=$?
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
