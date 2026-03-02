#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_misc.cpp" "tests/test_misc.cpp"

# Rebuild to incorporate the new test file
rm -rf build
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=20 \
    -DSPDLOG_BUILD_TESTS=ON \
    -DSPDLOG_BUILD_TESTS_HO=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_USE_STD_FORMAT=ON || {
    echo "CMake configuration failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

make -j2 || {
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
# Run only the os test (the specific test for this PR)
./build/tests/spdlog-utests "[os]"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
