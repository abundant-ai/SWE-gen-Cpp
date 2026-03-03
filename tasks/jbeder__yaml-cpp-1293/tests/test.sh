#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/fptostring_test.cpp" "test/fptostring_test.cpp"
mkdir -p "test/integration"
cp "/tests/integration/emitter_test.cpp" "test/integration/emitter_test.cpp"
mkdir -p "test/node"
cp "/tests/node/node_test.cpp" "test/node/node_test.cpp"

# Rebuild yaml-cpp (oracle applies fix.patch before running this script,
# so we need to rebuild to get the fixed version)

# Fix GoogleTest 1.10.0 compilation with modern GCC
# Remove -Werror flags from GoogleTest CMake cache
sed -i 's/-Werror[^ ]*//g' build/test/prefix/googletest/CMakeFiles/gtest.dir/flags.make 2>/dev/null || true
sed -i 's/-Werror[^ ]*//g' build/test/prefix/googletest/CMakeFiles/gtest_main.dir/flags.make 2>/dev/null || true

cmake --build build --config Debug 2>&1
rebuild_status=$?

if [ $rebuild_status -ne 0 ]; then
  echo "Rebuild failed with status $rebuild_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $rebuild_status
fi

# Run the specific tests for PR #1293
# Tests: FpToStringTest (fptostring_test.cpp), EmitterTest (emitter_test.cpp), NodeEmitterTest.RobustAgainstLocale (node_test.cpp)
./build/test/yaml-cpp-tests --gtest_filter="FpToStringTest.*:EmitterTest.*:NodeEmitterTest.RobustAgainstLocale" 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
