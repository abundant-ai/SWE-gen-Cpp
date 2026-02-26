#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/clobber_memory_assembly_test.cc" "test/clobber_memory_assembly_test.cc"
mkdir -p "test"
cp "/tests/donotoptimize_assembly_test.cc" "test/donotoptimize_assembly_test.cc"

# This PR adds NVHPC compiler support to the benchmark library
# Test: Check if the main source code has NVHPC support
# In BASE state (buggy), these should be MISSING from the main code
# In HEAD state (fixed), these should be PRESENT in the main code

echo "Checking if main source code has NVHPC support..."
test_status=0

# Check 1: benchmark.h should have NVHPC-specific macro definitions
echo "Checking include/benchmark/benchmark.h for NVHPC support..."
if grep -q "__NVCOMPILER" include/benchmark/benchmark.h && \
   grep -A 3 "elif defined(__NVCOMPILER)" include/benchmark/benchmark.h | grep -q "BENCHMARK_DISABLE_DEPRECATED_WARNING"; then
  echo "✓ benchmark.h has NVHPC macro definitions"
else
  echo "✗ benchmark.h missing NVHPC macro definitions"
  test_status=1
fi

# Check 2: benchmark.cc should have NVHPC pragmas
echo "Checking src/benchmark.cc for NVHPC pragmas..."
if grep -q "__NVCOMPILER" src/benchmark.cc && \
   grep -q "diag_suppress" src/benchmark.cc; then
  echo "✓ benchmark.cc has NVHPC pragmas"
else
  echo "✗ benchmark.cc missing NVHPC pragmas"
  test_status=1
fi

# Check 3: timers.cc should have NVHPC pragmas
echo "Checking src/timers.cc for NVHPC pragmas..."
if grep -q "__NVCOMPILER" src/timers.cc && \
   grep -q "diag_suppress" src/timers.cc; then
  echo "✓ timers.cc has NVHPC pragmas"
else
  echo "✗ timers.cc missing NVHPC pragmas"
  test_status=1
fi

# Check 4: Test files should use the macro (these come from /tests/ and should always have it)
echo "Checking test files for BENCHMARK_DISABLE_DEPRECATED_WARNING..."
if grep -q "BENCHMARK_DISABLE_DEPRECATED_WARNING" test/clobber_memory_assembly_test.cc && \
   grep -q "BENCHMARK_DISABLE_DEPRECATED_WARNING" test/donotoptimize_assembly_test.cc; then
  echo "✓ Test files use BENCHMARK_DISABLE_DEPRECATED_WARNING"
else
  echo "✗ Test files missing BENCHMARK_DISABLE_DEPRECATED_WARNING"
  test_status=1
fi

# Check 5: CMakeLists.txt should have NVHPC compiler options
echo "Checking test/CMakeLists.txt for NVHPC support..."
if grep -q "NVHPC" test/CMakeLists.txt && grep -q "diag_suppress" test/CMakeLists.txt; then
  echo "✓ CMakeLists.txt has NVHPC compiler options"
else
  echo "✗ CMakeLists.txt missing NVHPC compiler options"
  test_status=1
fi

# Rebuild to ensure everything compiles
echo "Rebuilding..."
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
