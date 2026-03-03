#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
mkdir -p "test"
cp "/tests/display_aggregates_only_test.cc" "test/display_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/memory_manager_test.cc" "test/memory_manager_test.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
mkdir -p "test"
cp "/tests/report_aggregates_only_test.cc" "test/report_aggregates_only_test.cc"
mkdir -p "test"
cp "/tests/reporter_output_test.cc" "test/reporter_output_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"
mkdir -p "test"
cp "/tests/user_counters_tabular_test.cc" "test/user_counters_tabular_test.cc"
mkdir -p "test"
cp "/tests/user_counters_test.cc" "test/user_counters_test.cc"
mkdir -p "test"
cp "/tests/user_counters_thousands_test.cc" "test/user_counters_thousands_test.cc"

# Initialize test_status
test_status=0

# Reconfigure CMake after copying CMakeLists.txt to pick up any changes
cd /app/src
rm -rf build/CMakeCache.txt build/CMakeFiles
cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
    -DBENCHMARK_ENABLE_TESTING=ON \
    -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
    -DBENCHMARK_ENABLE_ASSEMBLY_TESTS=ON \
    -DLLVM_FILECHECK_EXE=/usr/bin/FileCheck-18 \
    -DBENCHMARK_ENABLE_WERROR=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Rebuild the benchmark library first to pick up any source changes from fix.patch
cd /app/src
cmake --build build --config Debug --target benchmark -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark library"
    test_status=1
fi

# Rebuild benchmark_main library to pick up changes
cmake --build build --config Debug --target benchmark_main -j 1
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark_main library"
    test_status=1
fi

# Build the output_test_helper library needed by the tests
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target output_test_helper -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build output_test_helper"
        test_status=1
    fi
fi

# Build and run complexity_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target complexity_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build complexity_test"
        test_status=1
    else
        ./build/test/complexity_test
        if [ $? -ne 0 ]; then
            echo "complexity_test failed"
            test_status=1
        fi
    fi
fi

# Build and run display_aggregates_only_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target display_aggregates_only_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build display_aggregates_only_test"
        test_status=1
    else
        ./build/test/display_aggregates_only_test
        if [ $? -ne 0 ]; then
            echo "display_aggregates_only_test failed"
            test_status=1
        fi
    fi
fi

# Build and run memory_manager_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target memory_manager_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build memory_manager_test"
        test_status=1
    else
        ./build/test/memory_manager_test
        if [ $? -ne 0 ]; then
            echo "memory_manager_test failed"
            test_status=1
        fi
    fi
fi

# Build and run register_benchmark_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target register_benchmark_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build register_benchmark_test"
        test_status=1
    else
        ./build/test/register_benchmark_test
        if [ $? -ne 0 ]; then
            echo "register_benchmark_test failed"
            test_status=1
        fi
    fi
fi

# Build and run report_aggregates_only_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target report_aggregates_only_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build report_aggregates_only_test"
        test_status=1
    else
        ./build/test/report_aggregates_only_test
        if [ $? -ne 0 ]; then
            echo "report_aggregates_only_test failed"
            test_status=1
        fi
    fi
fi

# Build and run reporter_output_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target reporter_output_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build reporter_output_test"
        test_status=1
    else
        ./build/test/reporter_output_test
        if [ $? -ne 0 ]; then
            echo "reporter_output_test failed"
            test_status=1
        fi
    fi
fi

# Build and run skip_with_error_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target skip_with_error_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build skip_with_error_test"
        test_status=1
    else
        ./build/test/skip_with_error_test
        if [ $? -ne 0 ]; then
            echo "skip_with_error_test failed"
            test_status=1
        fi
    fi
fi

# Build and run user_counters_tabular_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target user_counters_tabular_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build user_counters_tabular_test"
        test_status=1
    else
        ./build/test/user_counters_tabular_test --benchmark_counters_tabular=true --benchmark_min_time=0.01
        if [ $? -ne 0 ]; then
            echo "user_counters_tabular_test failed"
            test_status=1
        fi
    fi
fi

# Build and run user_counters_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target user_counters_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build user_counters_test"
        test_status=1
    else
        ./build/test/user_counters_test
        if [ $? -ne 0 ]; then
            echo "user_counters_test failed"
            test_status=1
        fi
    fi
fi

# Build and run user_counters_thousands_test
if [ $test_status -eq 0 ]; then
    cmake --build build --config Debug --target user_counters_thousands_test -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build user_counters_thousands_test"
        test_status=1
    else
        ./build/test/user_counters_thousands_test
        if [ $? -ne 0 ]; then
            echo "user_counters_thousands_test failed"
            test_status=1
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
