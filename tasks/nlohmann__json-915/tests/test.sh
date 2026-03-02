#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/data/json_roundtrip"
cp "/tests/data/json_roundtrip/roundtrip27.json" "test/data/json_roundtrip/roundtrip27.json"
mkdir -p "test/data/json_roundtrip"
cp "/tests/data/json_roundtrip/roundtrip30.json" "test/data/json_roundtrip/roundtrip30.json"
mkdir -p "test/data/json_roundtrip"
cp "/tests/data/json_roundtrip/roundtrip31.json" "test/data/json_roundtrip/roundtrip31.json"
mkdir -p "test/src"
cp "/tests/src/unit-regression.cpp" "test/src/unit-regression.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-testsuites.cpp" "test/src/unit-testsuites.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-to_chars.cpp" "test/src/unit-to_chars.cpp"

# Rebuild and run the specific tests using CMake
build_output=$(cmake --build build --target test-regression test-testsuites test-to_chars 2>&1)
build_status=$?

# If build failed, tests fail
if [ $build_status -ne 0 ]; then
    echo "$build_output"
    echo "Build failed with status $build_status"
    test_status=1
else
    # Run test-regression
    test_output1=$(./build/test/test-regression 2>&1)
    test_exit1=$?
    echo "$test_output1"

    # Run test-testsuites
    test_output2=$(./build/test/test-testsuites 2>&1)
    test_exit2=$?
    echo "$test_output2"

    # Run test-to_chars
    test_output3=$(./build/test/test-to_chars 2>&1)
    test_exit3=$?
    echo "$test_output3"

    if [ $test_exit1 -ne 0 ] || echo "$test_output1" | grep -q "No tests ran"; then
        test_status=1
    elif [ $test_exit2 -ne 0 ] || echo "$test_output2" | grep -q "No tests ran"; then
        test_status=1
    elif [ $test_exit3 -ne 0 ] || echo "$test_output3" | grep -q "No tests ran"; then
        test_status=1
    else
        test_status=0
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
