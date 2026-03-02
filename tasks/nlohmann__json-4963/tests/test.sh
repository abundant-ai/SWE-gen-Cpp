#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/src"
cp "/tests/src/unit-deserialization.cpp" "tests/src/unit-deserialization.cpp"
cp "/tests/src/unit-json_pointer.cpp" "tests/src/unit-json_pointer.cpp"

# Rebuild the tests with the updated code (from /tests)
cd build
if ! cmake --build . --target test-deserialization_cpp20 --target test-json_pointer_cpp20; then
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executables (C++20 for char8_t support)
cd tests
./test-deserialization_cpp20
test_status_1=$?

./test-json_pointer_cpp20
test_status_2=$?

# Both tests must pass
if [ $test_status_1 -eq 0 ] && [ $test_status_2 -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
