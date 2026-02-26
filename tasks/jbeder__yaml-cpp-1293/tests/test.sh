#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/fptostring_test.cpp" "test/fptostring_test.cpp"
mkdir -p "test/integration"
cp "/tests/integration/emitter_test.cpp" "test/integration/emitter_test.cpp"
mkdir -p "test/node"
cp "/tests/node/node_test.cpp" "test/node/node_test.cpp"

# Clean and rebuild to ensure test file changes are picked up
rm -f build/test/yaml-cpp-tests \
    build/test/CMakeFiles/yaml-cpp-tests.dir/fptostring_test.cpp.o \
    build/test/CMakeFiles/yaml-cpp-tests.dir/integration/emitter_test.cpp.o \
    build/test/CMakeFiles/yaml-cpp-tests.dir/node/node_test.cpp.o
cmake --build build --config Debug
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Build failed with status $build_status" >&2
  echo 0 > /logs/verifier/reward.txt
  exit $build_status
fi

# Run the specific tests using Google Test filters
./build/test/yaml-cpp-tests --gtest_filter="FpToStringTest.*:EmitterTest.*:NodeTest.*"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
