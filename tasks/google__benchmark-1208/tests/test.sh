#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/benchmark_test.cc" "test/benchmark_test.cc"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Rebuild with the fixed test files
echo "Rebuilding with fixed test files..."
rm -rf build
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build everything to ensure all dependencies are correct
cmake --build build --config Debug -j 1

# Run the specific tests
./build/test/benchmark_test --benchmark_min_time=0.01
status1=$?

./build/test/fixture_test --benchmark_min_time=0.01
status2=$?

./build/test/skip_with_error_test --benchmark_min_time=0.01
status3=$?

# Check if all tests passed
if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
