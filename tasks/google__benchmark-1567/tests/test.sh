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

# Verify the fix: check that const char* has been converted to const std::string&
# The fix converts the API from const char* to const std::string& for better C++ practices

# Check benchmark.h has std::string API (not const char*)
# SetLabel should take const std::string&, not const char*
if grep -q 'void SetLabel(const std::string& label);' include/benchmark/benchmark.h; then
    echo "✓ benchmark.h SetLabel uses std::string&"
else
    echo "✗ benchmark.h SetLabel should use std::string&"
    test_status=1
fi

# RegisterBenchmark should take const std::string&, not const char*
if grep -q 'internal::Benchmark\* RegisterBenchmark(const std::string& name,' include/benchmark/benchmark.h; then
    echo "✓ benchmark.h RegisterBenchmark uses std::string&"
else
    echo "✗ benchmark.h RegisterBenchmark should use std::string&"
    test_status=1
fi

# Benchmark constructor should take const std::string&
if grep -q 'explicit Benchmark(const std::string& name);' include/benchmark/benchmark.h; then
    echo "✓ benchmark.h Benchmark constructor uses std::string&"
else
    echo "✗ benchmark.h Benchmark constructor should use std::string&"
    test_status=1
fi

# Check benchmark.cc has std::string implementation
if grep -q 'void State::SetLabel(const std::string& label)' src/benchmark.cc; then
    echo "✓ benchmark.cc SetLabel implementation uses std::string&"
else
    echo "✗ benchmark.cc SetLabel should use std::string&"
    test_status=1
fi

# Check benchmark_register.cc has std::string implementation
if grep -q 'Benchmark::Benchmark(const std::string& name)' src/benchmark_register.cc; then
    echo "✓ benchmark_register.cc Benchmark constructor uses std::string&"
else
    echo "✗ benchmark_register.cc Benchmark constructor should use std::string&"
    test_status=1
fi

# If all checks passed, test_status should still be unset (0)
if [ -z "$test_status" ]; then
    echo "✓ All API signature checks passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
