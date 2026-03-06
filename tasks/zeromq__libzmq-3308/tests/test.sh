#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_ctx_options.cpp" "tests/test_ctx_options.cpp"
mkdir -p "tests"
cp "/tests/test_monitor.cpp" "tests/test_monitor.cpp"
mkdir -p "tests"
cp "/tests/test_proxy.cpp" "tests/test_proxy.cpp"
mkdir -p "tests"
cp "/tests/test_proxy_hwm.cpp" "tests/test_proxy_hwm.cpp"
mkdir -p "tests"
cp "/tests/test_security_curve.cpp" "tests/test_security_curve.cpp"
mkdir -p "tests"
cp "/tests/test_security_gssapi.cpp" "tests/test_security_gssapi.cpp"
mkdir -p "tests"
cp "/tests/test_security_zap.cpp" "tests/test_security_zap.cpp"
mkdir -p "tests"
cp "/tests/test_timers.cpp" "tests/test_timers.cpp"
mkdir -p "tests"
cp "/tests/testutil_security.hpp" "tests/testutil_security.hpp"

# Rebuild with the updated test files to test the fixed version
rm -rf build
mkdir -p build
cd build
cmake .. -DENABLE_DRAFTS=ON -DBUILD_TESTS=ON -DWITH_GSSAPI_KRB5=ON

# Build the specific tests (excluding test_security_gssapi which is not a CMake target)
make -j$(nproc) test_ctx_options test_monitor test_proxy test_proxy_hwm test_security_curve test_security_zap test_timers
build_status=$?

if [ $build_status -ne 0 ]; then
    test_status=$build_status
else
    # Run each test individually
    test_status=0
    for test_name in test_ctx_options test_monitor test_proxy test_proxy_hwm test_security_curve test_security_zap test_timers; do
        echo "Running $test_name..."
        ./bin/"$test_name"
        run_status=$?
        if [ $run_status -ne 0 ]; then
            echo "Test $test_name failed with exit code $run_status"
            test_status=$run_status
            break
        fi
        echo "Test $test_name passed"
    done
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
