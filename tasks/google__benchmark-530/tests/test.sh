#!/bin/bash

cd /app/src

test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/AssemblyTests.cmake" "test/AssemblyTests.cmake"
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"
mkdir -p "test"
cp "/tests/CMakeLists.txt" "test/CMakeLists.txt"
mkdir -p "test"
cp "/tests/clobber_memory_assembly_test.cc" "test/clobber_memory_assembly_test.cc"
mkdir -p "test"
cp "/tests/donotoptimize_assembly_test.cc" "test/donotoptimize_assembly_test.cc"
mkdir -p "test"
cp "/tests/state_assembly_test.cc" "test/state_assembly_test.cc"

# Also need to copy tools/strip_asm.py which is required by assembly tests
mkdir -p "tools"
cp "/tests/strip_asm.py" "tools/strip_asm.py"
chmod +x "tools/strip_asm.py"

# Verify the assembly test infrastructure was added
# Check that key files exist
if [ ! -f "test/AssemblyTests.cmake" ]; then
    echo "ERROR: test/AssemblyTests.cmake not found" >&2
    test_status=1
fi

if [ ! -f "test/donotoptimize_assembly_test.cc" ]; then
    echo "ERROR: test/donotoptimize_assembly_test.cc not found" >&2
    test_status=1
fi

if [ ! -f "tools/strip_asm.py" ]; then
    echo "ERROR: tools/strip_asm.py not found" >&2
    test_status=1
fi

# Verify that the CMakeLists.txt includes BENCHMARK_ENABLE_ASSEMBLY_TESTS
# This option is added by the fix, and removed in the buggy state
if ! grep -q "BENCHMARK_ENABLE_ASSEMBLY_TESTS" "CMakeLists.txt"; then
    echo "ERROR: BENCHMARK_ENABLE_ASSEMBLY_TESTS not found in CMakeLists.txt" >&2
    echo "This indicates the fix was not applied to enable assembly test infrastructure" >&2
    test_status=1
fi

# Verify that the test/CMakeLists.txt references AssemblyTests.cmake
if ! grep -q "include(AssemblyTests.cmake)" "test/CMakeLists.txt"; then
    echo "ERROR: test/CMakeLists.txt does not include AssemblyTests.cmake" >&2
    test_status=1
fi

# Verify that docs/AssemblyTests.md was added (part of the fix)
if [ ! -f "docs/AssemblyTests.md" ]; then
    echo "ERROR: docs/AssemblyTests.md not found - fix may not be fully applied" >&2
    test_status=1
fi

# Verify the DoNotOptimize implementation was fixed
# The fix changes DoNotOptimize to have separate overloads for const and non-const
if ! grep -q "void DoNotOptimize(Tp& value)" "include/benchmark/benchmark.h"; then
    echo "ERROR: DoNotOptimize fix not found in benchmark.h" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
