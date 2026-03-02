#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_mpmc_q.cpp" "tests/test_mpmc_q.cpp"

# Rebuild to incorporate the new test files
rm -rf build
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DSPDLOG_BUILD_TESTS=ON \
    -DSPDLOG_BUILD_TESTS_HO=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

make -j2 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Check if test binary was built successfully
if [ ! -f tests/spdlog-utests ]; then
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

cd ..
# Run only the mpmc_blocking_q tests (the specific tests for this PR)
./build/tests/spdlog-utests "[mpmc_blocking_q]"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
