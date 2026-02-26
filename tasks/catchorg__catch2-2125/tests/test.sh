#!/bin/bash

cd /app/src

# Copy HEAD test source files and baselines from /tests (these are not modified by fix.patch - only updated to match the modern casts)
mkdir -p "tests/SelfTest/Baselines"
cp "/tests/SelfTest/Baselines/compact.sw.approved.txt" "tests/SelfTest/Baselines/compact.sw.approved.txt"
cp "/tests/SelfTest/Baselines/console.sw.approved.txt" "tests/SelfTest/Baselines/console.sw.approved.txt"
cp "/tests/SelfTest/Baselines/tap.sw.approved.txt" "tests/SelfTest/Baselines/tap.sw.approved.txt"
cp "/tests/SelfTest/Baselines/xml.sw.approved.txt" "tests/SelfTest/Baselines/xml.sw.approved.txt"
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/String.tests.cpp" "tests/SelfTest/IntrospectiveTests/String.tests.cpp"
cp "/tests/SelfTest/IntrospectiveTests/Xml.tests.cpp" "tests/SelfTest/IntrospectiveTests/Xml.tests.cpp"

# Verify that -Wold-style-cast is enabled in CMake (only present if fix was applied)
if ! grep -q '"-Wold-style-cast"' CMake/MiscFunctions.cmake; then
    echo "FAIL: -Wold-style-cast flag not enabled in CMake - fix not applied"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Reconfigure CMake to pick up any changes
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja 2>&1; then
    echo "FAIL: CMake reconfiguration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Rebuild - this will FAIL if old-style casts are still present, PASS if modern casts are used
if ! cmake --build build 2>&1; then
    echo "FAIL: Build failed with -Wold-style-cast enabled - old-style casts still present"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the StringRef tests to verify they pass
if ! ./build/tests/SelfTest "[StringRef]" 2>&1; then
    echo "FAIL: StringRef tests did not pass"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "SUCCESS: All checks passed - fix properly applied"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
