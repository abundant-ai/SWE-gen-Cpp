#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests/src"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"
cp "/tests/src/unit-wstring.cpp" "tests/src/unit-wstring.cpp"

# Re-configure with CI=On to enable CI targets including ci_icpc
cmake -S . -B build_test -DJSON_CI=On > /tmp/cmake_output.txt 2>&1
cmake_status=$?

if [ $cmake_status -ne 0 ]; then
    cat /tmp/cmake_output.txt
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# The fix adds Intel C++ compiler support including the ci_icpc target
# At BASE (buggy), this target is removed
# At HEAD (fixed), this target exists
# Check if the ci_icpc target exists
echo "Checking if ci_icpc target exists..."
if cmake --build build_test --target help | grep -q "ci_icpc"; then
    echo "SUCCESS: ci_icpc target found (Intel compiler support present)"
    test_status=0
else
    echo "FAIL: ci_icpc target not found (Intel compiler support missing)"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
