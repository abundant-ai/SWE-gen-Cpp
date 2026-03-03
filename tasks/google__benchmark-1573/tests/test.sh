#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/clobber_memory_assembly_test.cc" "test/clobber_memory_assembly_test.cc"
mkdir -p "test"
cp "/tests/donotoptimize_assembly_test.cc" "test/donotoptimize_assembly_test.cc"

# Verify the fix: check that NVHPC compiler support was added
# The fix should add BENCHMARK_DISABLE_DEPRECATED_WARNING macros and other NVHPC-specific pragmas

# Check benchmark.h has NVHPC support
if grep -q '__NVCOMPILER' include/benchmark/benchmark.h && \
   grep -q 'BENCHMARK_DISABLE_DEPRECATED_WARNING' include/benchmark/benchmark.h && \
   grep -q 'diag_suppress deprecated_entity_with_custom_message' include/benchmark/benchmark.h; then
    echo "✓ benchmark.h has NVHPC support"
else
    echo "✗ benchmark.h missing NVHPC support"
    test_status=1
fi

# Check benchmark.cc has NVHPC pragmas
if grep -q '__NVCOMPILER' src/benchmark.cc && \
   grep -q 'diag_suppress offset_in_non_POD_nonstandard' src/benchmark.cc; then
    echo "✓ benchmark.cc has NVHPC pragmas"
else
    echo "✗ benchmark.cc missing NVHPC pragmas"
    test_status=1
fi

# Check timers.cc has NVHPC pragmas
if grep -q '__NVCOMPILER' src/timers.cc && \
   grep -q 'diag_suppress declared_but_not_referenced' src/timers.cc; then
    echo "✓ timers.cc has NVHPC pragmas"
else
    echo "✗ timers.cc missing NVHPC pragmas"
    test_status=1
fi

# Check test/CMakeLists.txt has NVHPC compile options
if grep -q 'NVHPC' test/CMakeLists.txt && \
   grep -q 'diag_suppress partial_override' test/CMakeLists.txt; then
    echo "✓ test/CMakeLists.txt has NVHPC compile options"
else
    echo "✗ test/CMakeLists.txt missing NVHPC compile options"
    test_status=1
fi

# Check assembly test files have BENCHMARK_DISABLE_DEPRECATED_WARNING
if grep -q 'BENCHMARK_DISABLE_DEPRECATED_WARNING' test/clobber_memory_assembly_test.cc && \
   grep -q 'BENCHMARK_DISABLE_DEPRECATED_WARNING' test/donotoptimize_assembly_test.cc; then
    echo "✓ Assembly tests have BENCHMARK_DISABLE_DEPRECATED_WARNING"
else
    echo "✗ Assembly tests missing BENCHMARK_DISABLE_DEPRECATED_WARNING"
    test_status=1
fi

# If all checks passed, test_status should still be unset (0)
if [ -z "$test_status" ]; then
    echo "✓ All NVHPC support checks passed"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
