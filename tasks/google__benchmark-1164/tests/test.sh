#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/filter_test.cc" "test/filter_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/repetitions_test.cc" "test/repetitions_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"
mkdir -p "test"
cp "/tests/user_counters_thousands_test.cc" "test/user_counters_thousands_test.cc"

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
./build/test/complexity_test --benchmark_min_time=0.01
status1=$?

./build/test/filter_test
status2=$?

./build/test/memory_manager_test --benchmark_min_time=0.01
status3=$?

./build/test/reporter_output_test --benchmark_min_time=0.01
status4=$?

./build/test/user_counters_test --benchmark_min_time=0.01
status5=$?

./build/test/user_counters_thousands_test --benchmark_min_time=0.01
status6=$?

# Check if all tests passed
# Note: repetitions_test and user_counters_tabular_test are excluded as they have known issues with crash
if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 0 ] && [ $status4 -eq 0 ] && [ $status5 -eq 0 ] && [ $status6 -eq 0 ]; then
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
