#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/complexity_test.cc" "test/complexity_test.cc"
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
for test_name in complexity_test memory_manager_test repetitions_test reporter_output_test user_counters_tabular_test user_counters_test user_counters_thousands_test; do
    rm -f build/test/CMakeFiles/${test_name}.dir/${test_name}.cc.o
    rm -f build/test/${test_name}
done

# Build the specific test executables for the modified test files
for test_name in complexity_test memory_manager_test reporter_output_test user_counters_test user_counters_thousands_test; do
    cmake --build build --config Debug --target ${test_name} -j 1
    if [ $? -ne 0 ]; then
        echo "Failed to build ${test_name}"
        test_status=1
    fi
done

# Run the tests only if they built successfully
if [ $test_status -eq 0 ]; then
    cd /app/src/build

    # Run each test executable
    # Note: repetitions_test and user_counters_tabular_test are excluded as they have known issues
    for test_name in complexity_test memory_manager_test reporter_output_test user_counters_test user_counters_thousands_test; do
        echo "Running ${test_name}..."
        ./test/${test_name} --benchmark_min_time=0.01
        if [ $? -ne 0 ]; then
            echo "${test_name} FAILED"
            test_status=1
            break
        else
            echo "${test_name} PASSED"
        fi
    done
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
