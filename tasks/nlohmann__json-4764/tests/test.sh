#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/module_cpp20"
cp "/tests/module_cpp20/CMakeLists.txt" "tests/module_cpp20/CMakeLists.txt"
cp "/tests/module_cpp20/json.cpp" "tests/module_cpp20/json.cpp"
cp "/tests/module_cpp20/main.cpp" "tests/module_cpp20/main.cpp"
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"
cp "/tests/src/unit-user_defined_input.cpp" "tests/src/unit-user_defined_input.cpp"

# Build the test executables for unit-regression2.cpp and unit-user_defined_input.cpp
if ! cmake --build build --target test-regression2_cpp11; then
    echo "Build failed for test-regression2_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! cmake --build build --target test-user_defined_input_cpp11; then
    echo "Build failed for test-user_defined_input_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the unit tests
./build/tests/test-regression2_cpp11
test_status=$?
if [ $test_status -ne 0 ]; then
    echo "test-regression2_cpp11 failed"
    echo 0 > /logs/verifier/reward.txt
    exit $test_status
fi

./build/tests/test-user_defined_input_cpp11
test_status=$?
if [ $test_status -ne 0 ]; then
    echo "test-user_defined_input_cpp11 failed"
    echo 0 > /logs/verifier/reward.txt
    exit $test_status
fi

# Try to build the module_cpp20 test (uses GCC to catch linkage errors)
# In BASE state (with static linkage), this should fail
# In HEAD state (with inline linkage), this should succeed
cd tests/module_cpp20
rm -rf build_module
cmake -S . -B build_module -G Ninja -DCMAKE_BUILD_TYPE=Debug > /dev/null 2>&1
if cmake --build build_module > /dev/null 2>&1; then
    # Module compilation succeeded - this is the fixed (HEAD) state
    if ./build_module/json_test > /dev/null 2>&1; then
        cd /app/src
        echo 1 > /logs/verifier/reward.txt
        exit 0
    else
        # Module test ran but failed
        cd /app/src
        echo 0 > /logs/verifier/reward.txt
        exit 1
    fi
else
    # Module compilation failed - this is the buggy (BASE) state
    cd /app/src
    echo 0 > /logs/verifier/reward.txt
    exit 0
fi
