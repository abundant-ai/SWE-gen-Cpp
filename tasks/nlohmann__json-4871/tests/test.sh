#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-conversions.cpp" "tests/src/unit-conversions.cpp"
cp "/tests/src/unit-noexcept.cpp" "tests/src/unit-noexcept.cpp"
cp "/tests/src/unit-regression1.cpp" "tests/src/unit-regression1.cpp"
cp "/tests/src/unit-regression2.cpp" "tests/src/unit-regression2.cpp"

# Rebuild the tests with the updated code (from /tests)
cd build
if ! cmake --build . --target test-conversions_cpp11; then
    echo "Build failed for test-conversions_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
if ! cmake --build . --target test-noexcept_cpp11; then
    echo "Build failed for test-noexcept_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
if ! cmake --build . --target test-regression1_cpp11; then
    echo "Build failed for test-regression1_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
if ! cmake --build . --target test-regression2_cpp11; then
    echo "Build failed for test-regression2_cpp11"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executables
cd tests
./test-conversions_cpp11 && ./test-noexcept_cpp11 && ./test-regression1_cpp11 && ./test-regression2_cpp11
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
