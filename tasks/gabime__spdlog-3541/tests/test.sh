#!/bin/bash

cd /app/src

# Reconfigure build with C++20 and SPDLOG_USE_STD_FORMAT to test the bug
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_FLAGS="-Werror=deprecated-declarations" \
    -DSPDLOG_BUILD_TESTS=ON \
    -DSPDLOG_BUILD_TESTS_HO=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_USE_STD_FORMAT=ON \
    -DSPDLOG_BUILD_WARNINGS=ON

# Clean and rebuild - use -j2 to avoid OOM with C++20
make clean
make -j2 2>&1 | tee /tmp/build.log

# Check if test binary was built successfully
if [ ! -f tests/spdlog-utests ]; then
    echo "Build failed - buggy state detected"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

cd ..
# Run the tests
./build/tests/spdlog-utests "[fmt_helper],[pattern_formatter]"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
