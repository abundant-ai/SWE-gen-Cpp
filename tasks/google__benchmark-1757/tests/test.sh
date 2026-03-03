#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/basic_test.cc" "test/basic_test.cc"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/diagnostics_test.cc" "test/diagnostics_test.cc"
mkdir -p "test"
cp "/tests/link_main_test.cc" "test/link_main_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/perf_counters_test.cc" "test/perf_counters_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"

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

# Build the specific test targets
cmake --build build --config Debug -j 1
if [ $? -ne 0 ]; then
    echo "Build failed!"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific tests using ctest
echo "Running tests..."
cd build
ctest -R "^(basic_benchmark|complexity_benchmark|diagnostics_test|link_main_test|memory_manager_test|perf_counters_test|reporter_output_test|skip_with_error_test|user_counters_tabular_test|user_counters_test)$" -VV --output-on-failure
test_status=$?
cd ..

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
