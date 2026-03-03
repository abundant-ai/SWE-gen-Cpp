#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests to enable checkimplementation test
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/add_cpp_test.cmake" "tests/add_cpp_test.cmake"
mkdir -p "tests"
cp "/tests/checkimplementation.cpp" "tests/checkimplementation.cpp"
mkdir -p "tests/compilation_failure_tests"
cp "/tests/compilation_failure_tests/CMakeLists.txt" "tests/compilation_failure_tests/CMakeLists.txt"

# Rebuild to include checkimplementation test
echo "Rebuilding with checkimplementation test..."
rm -rf build
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_DEVELOPMENT_CHECKS=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    echo "ERROR: CMake configuration failed"
    test_status=1
else
    # Build checkimplementation test
    echo "Building checkimplementation..."
    cmake --build build --target checkimplementation 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "ERROR: Failed to build checkimplementation"
        test_status=1
    else
        # Run checkimplementation with SIMDJSON_FORCE_IMPLEMENTATION set
        # This will fail with buggy code (which doesn't support the env var)
        # and succeed with fixed code (which does support it)
        echo "Running checkimplementation with SIMDJSON_FORCE_IMPLEMENTATION=fallback..."
        SIMDJSON_FORCE_IMPLEMENTATION=fallback ./build/tests/checkimplementation 2>&1
        test_status=$?

        if [ $test_status -eq 0 ]; then
            echo "SUCCESS: checkimplementation passed with SIMDJSON_FORCE_IMPLEMENTATION support"
        else
            echo "ERROR: checkimplementation failed - SIMDJSON_FORCE_IMPLEMENTATION not supported or wrong implementation"
        fi
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
