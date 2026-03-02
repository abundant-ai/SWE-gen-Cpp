#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_pattern_formatter.cpp" "tests/test_pattern_formatter.cpp"
mkdir -p "tests"
cp "/tests/test_stdout_api.cpp" "tests/test_stdout_api.cpp"

# Reconfigure build to test the timezone offset functionality
# Remove build directory and start fresh to avoid cached flags
rm -rf build
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=11 \
    -DSPDLOG_BUILD_TESTS=ON \
    -DSPDLOG_BUILD_TESTS_HO=OFF \
    -DSPDLOG_BUILD_EXAMPLE=OFF \
    -DSPDLOG_NO_TZ_OFFSET=ON 2>&1 | tee /tmp/cmake.log

# Check if the SPDLOG_NO_TZ_OFFSET macro will actually be defined
# In the fixed state, the option exists and will add -DSPDLOG_NO_TZ_OFFSET to compile flags
# In the buggy state, the option doesn't exist in CMakeLists.txt, so the macro won't be defined
if grep -r "DSPDLOG_NO_TZ_OFFSET" . 2>/dev/null | grep -q "flags.make"; then
    echo "SPDLOG_NO_TZ_OFFSET option exists and will be applied (fixed state)"
else
    echo "SPDLOG_NO_TZ_OFFSET option doesn't properly propagate to compile definitions (buggy state)"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build with limited parallelism to avoid OOM
make -j2 2>&1 | tee /tmp/build.log

# Check if test binary was built successfully
if [ ! -f tests/spdlog-utests ]; then
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

cd ..
# Run the tests - should pass with SPDLOG_NO_TZ_OFFSET (using placeholder "+??:??")
./build/tests/spdlog-utests "[pattern_formatter]"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
