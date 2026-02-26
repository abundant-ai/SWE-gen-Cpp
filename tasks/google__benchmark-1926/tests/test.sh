#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
cp "/tests/BUILD" "test/BUILD"

# Reconfigure CMake to regenerate compile_commands.json
cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
  -DBENCHMARK_ENABLE_TESTING=ON \
  -DBENCHMARK_ENABLE_GTEST_TESTS=ON \
  -DBENCHMARK_ENABLE_WERROR=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Run clang-tidy on the specific files modified in this PR
# From bug.patch, the files modified are:
# - BUILD.bazel (removed MSVC_COPTS)
# - include/benchmark/benchmark.h (removed reinterpret_cast - this causes array-to-pointer decay warning)
# - src/check.h (changed to const char* from std::string_view)
# - test/BUILD (removed TEST_MSVC_OPTS)
#
# The key issue is in benchmark.h where reinterpret_cast was removed,
# causing an implicit array-to-pointer decay that clang-tidy flags.
cd /app/src
clang-tidy \
  -p build \
  --config-file=/app/src/.clang-tidy \
  include/benchmark/benchmark.h \
  src/check.h \
  2>&1 | tee /tmp/clang-tidy-output.txt

# Check for array-to-pointer decay warnings
# The bug introduces array decay in benchmark.h (line 1635: char* args_default = arg0_default)
# where arg0_default is defined as char arg0_default[] = "benchmark"
if grep -E "benchmark\.h.*cppcoreguidelines-pro-bounds-array-to-pointer-decay" /tmp/clang-tidy-output.txt ||
   grep -E "benchmark\.h.*array decaying" /tmp/clang-tidy-output.txt; then
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
