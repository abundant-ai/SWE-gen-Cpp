#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/output_test.h" "test/output_test.h"
mkdir -p "test"
cp "/tests/output_test_helper.cc" "test/output_test_helper.cc"
mkdir -p "test"
cp "/tests/register_benchmark_test.cc" "test/register_benchmark_test.cc"
mkdir -p "test"
cp "/tests/skip_with_error_test.cc" "test/skip_with_error_test.cc"

# This PR changes API signatures from const char* to const std::string& to prevent dangling pointer issues
# Test: Check if the source code has the correct string-based API signatures
# In BASE state (buggy), the API uses const char* (less safe)
# In HEAD state (fixed), the API uses const std::string& (safe, no dangling pointers)

echo "Checking if source code has safe string-based API signatures..."
test_status=0

# Check 1: benchmark.h should have SetLabel(const std::string&) as the primary overload
echo "Checking include/benchmark/benchmark.h for SetLabel signature..."
if grep -q "void SetLabel(const std::string& label);" include/benchmark/benchmark.h; then
  echo "✓ benchmark.h has SetLabel(const std::string&) signature"
else
  echo "✗ benchmark.h missing SetLabel(const std::string&) signature"
  test_status=1
fi

# Check 2: benchmark.h should have Benchmark constructor taking const std::string&
echo "Checking include/benchmark/benchmark.h for Benchmark constructor..."
if grep -q "explicit Benchmark(const std::string& name);" include/benchmark/benchmark.h; then
  echo "✓ benchmark.h has Benchmark(const std::string&) constructor"
else
  echo "✗ benchmark.h missing Benchmark(const std::string&) constructor"
  test_status=1
fi

# Check 3: benchmark.h should have SetName taking const std::string&
echo "Checking include/benchmark/benchmark.h for SetName signature..."
if grep -q "void SetName(const std::string& name);" include/benchmark/benchmark.h; then
  echo "✓ benchmark.h has SetName(const std::string&) signature"
else
  echo "✗ benchmark.h missing SetName(const std::string&) signature"
  test_status=1
fi

# Check 4: Test files should be able to use std::string types
echo "Checking test files for std::string usage..."
if grep -q "AddCases(const std::string& base_name" test/skip_with_error_test.cc; then
  echo "✓ skip_with_error_test.cc uses std::string in AddCases"
else
  echo "✗ skip_with_error_test.cc not using std::string in AddCases"
  test_status=1
fi

# Check 5: Test files should pass std::string objects (not just literals)
echo "Checking test files for std::string object usage..."
if grep -q "std::string(\"custom_fixture\")" test/register_benchmark_test.cc; then
  echo "✓ register_benchmark_test.cc uses std::string objects"
else
  echo "✗ register_benchmark_test.cc not using std::string objects"
  test_status=1
fi

# Rebuild to ensure everything compiles with the new API
echo "Rebuilding to verify compilation..."
if cmake --build build --config Debug -j 1 > /tmp/build.log 2>&1; then
  echo "✓ Build succeeded"
else
  echo "✗ Build failed"
  cat /tmp/build.log | tail -50
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
