#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"
mkdir -p "tests"
cp "/tests/test_mock_pub_sub.cpp" "tests/test_mock_pub_sub.cpp"

# Rebuild with the updated test files to test the fixed version
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build the specific test
make -j$(nproc) test_mock_pub_sub
build_status=$?

if [ $build_status -ne 0 ]; then
    test_status=$build_status
else
    # Run the test
    echo "Running test_mock_pub_sub..."
    ./bin/test_mock_pub_sub
    test_status=$?
    if [ $test_status -eq 0 ]; then
        echo "Test test_mock_pub_sub passed"
    else
        echo "Test test_mock_pub_sub failed with exit code $test_status"
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
