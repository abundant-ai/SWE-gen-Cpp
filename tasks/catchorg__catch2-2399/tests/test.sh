#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/CMakeLists.txt" "tests/ExtraTests/CMakeLists.txt"
mkdir -p "tests/ExtraTests"
cp "/tests/ExtraTests/X30-BazelReporter.cpp" "tests/ExtraTests/X30-BazelReporter.cpp"
mkdir -p "tests/TestScripts"
cp "/tests/TestScripts/testBazelReporter.py" "tests/TestScripts/testBazelReporter.py"

# Reconfigure CMake after copying test files (needed to register the new test)
if ! cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug -DCATCH_DEVELOPMENT_BUILD=ON -DCATCH_BUILD_TESTING=ON -DCATCH_BUILD_EXTRA_TESTS=ON -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" -G Ninja; then
    echo "CMake configuration failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild after copying the updated test files
if ! cmake --build build; then
    echo "Build failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the BazelReporter test using CTest
# This test validates the Bazel reporter functionality introduced in PR #2399
cd build
ctest -R CATCH_CONFIG_BAZEL_REPORTER-1 -V > /tmp/ctest_output.txt 2>&1
test_status=$?

# Check if test actually ran (CTest exits 0 even if no tests match the pattern)
if grep -q "Added 0 tests to meet fixture requirements" /tmp/ctest_output.txt && grep -q "Total Test time" /tmp/ctest_output.txt; then
    # Test ran successfully
    :
elif grep -q "Added 0 tests to meet fixture requirements" /tmp/ctest_output.txt; then
    # No tests found - this means the test doesn't exist (BASE state)
    echo "Test CATCH_CONFIG_BAZEL_REPORTER-1 not found - Bazel support not enabled"
    cat /tmp/ctest_output.txt
    test_status=1
fi

cat /tmp/ctest_output.txt

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
