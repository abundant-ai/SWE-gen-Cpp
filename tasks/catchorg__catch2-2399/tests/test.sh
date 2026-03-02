#!/bin/bash
set -eo pipefail

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/CMakeLists.txt" "tests/ExtraTests/CMakeLists.txt"
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/X30-BazelReporter.cpp" "tests/ExtraTests/X30-BazelReporter.cpp"
mkdir -p "tests/TestScripts"
cp "/tests/TestScripts/testBazelReporter.py" "tests/TestScripts/testBazelReporter.py"

# Reconfigure CMake to pick up the updated test files
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator -DCATCH_CONFIG_BAZEL_SUPPORT" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild to pick up changes (including the Bazel reporter test)
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the Python test script that validates the Bazel reporter functionality
# The test script will:
# 1. Run the X30-BazelReporter test binary with XML_OUTPUT_FILE set
# 2. Verify valid JUnit XML is created at the specified path
# 3. Verify the console output still shows the default reporter summary
mkdir -p /tmp/bazel-test-output
if ! python3 tests/TestScripts/testBazelReporter.py ./build/tests/ExtraTests/BazelReporter /tmp/bazel-test-output 2>&1 | tee /tmp/test_output.txt; then
    echo "FAIL: Bazel reporter test failed"
    cat /tmp/test_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: Bazel reporter test passed"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
