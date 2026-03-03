#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/args_product_test.cc" "test/args_product_test.cc"
mkdir -p "test"
cp "/tests/filter_test.cc" "test/filter_test.cc"
mkdir -p "test"
cp "/tests/fixture_test.cc" "test/fixture_test.cc"
mkdir -p "test"
cp "/tests/map_test.cc" "test/map_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/multiple_ranges_test.cc" "test/multiple_ranges_test.cc"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# Initialize test_status
test_status=0

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Remove old test object files to force rebuild with new test files
rm -f build/test/CMakeFiles/args_product_test.dir/args_product_test.cc.o
rm -f build/test/args_product_test
rm -f build/test/CMakeFiles/filter_test.dir/filter_test.cc.o
rm -f build/test/filter_test
rm -f build/test/CMakeFiles/fixture_test.dir/fixture_test.cc.o
rm -f build/test/fixture_test
rm -f build/test/CMakeFiles/map_test.dir/map_test.cc.o
rm -f build/test/map_test
rm -f build/test/CMakeFiles/memory_manager_test.dir/memory_manager_test.cc.o
rm -f build/test/memory_manager_test
rm -f build/test/CMakeFiles/multiple_ranges_test.dir/multiple_ranges_test.cc.o
rm -f build/test/multiple_ranges_test
rm -f build/test/CMakeFiles/output_test_helper.dir/output_test_helper.cc.o
rm -f build/test/liboutput_test_helper.a
rm -f build/test/CMakeFiles/register_benchmark_test.dir/register_benchmark_test.cc.o
rm -f build/test/register_benchmark_test
rm -f build/test/CMakeFiles/skip_with_error_test.dir/skip_with_error_test.cc.o
rm -f build/test/skip_with_error_test

# Build the specific test executables and library for the modified test files
# Note: output_test_helper is a library, not a test executable
cmake --build build --config Debug --target args_product_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build args_product_test"
    test_status=1
fi

cmake --build build --config Debug --target filter_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build filter_test"
    test_status=1
fi

cmake --build build --config Debug --target fixture_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build fixture_test"
    test_status=1
fi

cmake --build build --config Debug --target map_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build map_test"
    test_status=1
fi

cmake --build build --config Debug --target memory_manager_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build memory_manager_test"
    test_status=1
fi

cmake --build build --config Debug --target multiple_ranges_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build multiple_ranges_test"
    test_status=1
fi

cmake --build build --config Debug --target output_test_helper -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build output_test_helper library"
    test_status=1
fi

cmake --build build --config Debug --target register_benchmark_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build register_benchmark_test"
    test_status=1
fi

cmake --build build --config Debug --target skip_with_error_test -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build skip_with_error_test"
    test_status=1
fi

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    echo "Running args_product_test..."
    ./test/args_product_test
    if [ $? -ne 0 ]; then
        echo "args_product_test FAILED"
        test_status=1
    else
        echo "args_product_test PASSED"
    fi

    echo "Running filter_test..."
    ./test/filter_test
    if [ $? -ne 0 ]; then
        echo "filter_test FAILED"
        test_status=1
    else
        echo "filter_test PASSED"
    fi

    echo "Running fixture_test..."
    ./test/fixture_test
    if [ $? -ne 0 ]; then
        echo "fixture_test FAILED"
        test_status=1
    else
        echo "fixture_test PASSED"
    fi

    echo "Running map_test..."
    ./test/map_test
    if [ $? -ne 0 ]; then
        echo "map_test FAILED"
        test_status=1
    else
        echo "map_test PASSED"
    fi

    echo "Running memory_manager_test..."
    ./test/memory_manager_test
    if [ $? -ne 0 ]; then
        echo "memory_manager_test FAILED"
        test_status=1
    else
        echo "memory_manager_test PASSED"
    fi

    echo "Running multiple_ranges_test..."
    ./test/multiple_ranges_test
    if [ $? -ne 0 ]; then
        echo "multiple_ranges_test FAILED"
        test_status=1
    else
        echo "multiple_ranges_test PASSED"
    fi

    echo "Running register_benchmark_test..."
    ./test/register_benchmark_test
    if [ $? -ne 0 ]; then
        echo "register_benchmark_test FAILED"
        test_status=1
    else
        echo "register_benchmark_test PASSED"
    fi

    echo "Running skip_with_error_test..."
    ./test/skip_with_error_test
    if [ $? -ne 0 ]; then
        echo "skip_with_error_test FAILED"
        test_status=1
    else
        echo "skip_with_error_test PASSED"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
