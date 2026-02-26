#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/BUILD" "test/BUILD"

# Reconfigure CMake to regenerate compile_commands.json with clang
cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
  -DBENCHMARK_ENABLE_TESTING=ON \
  -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
  -DBENCHMARK_ENABLE_WERROR=OFF \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Run run-clang-tidy on all files (as done in CI)
# The key issue is in benchmark.h where reinterpret_cast was removed,
# causing an implicit array-to-pointer decay that clang-tidy should flag.
cd /app/src/build
run-clang-tidy -config-file=/app/src/.clang-tidy 2>&1 | tee /tmp/clang-tidy-output.txt

# Check for array-to-pointer decay warnings
# The bug introduces array decay in benchmark.h (line 1635: char* args_default = arg0_default)
# where arg0_default is defined as char arg0_default[] = "benchmark"
if grep -E "benchmark\.h.*cppcoreguidelines-pro-bounds-array-to-pointer-decay" /tmp/clang-tidy-output.txt ||
   grep -E "benchmark\.h.*array.*decay" /tmp/clang-tidy-output.txt; then
  echo "ERROR: Found array-to-pointer decay warning in benchmark.h" >&2
  test_status=1
else
  echo "SUCCESS: No array-to-pointer decay warnings found" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
