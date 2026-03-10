#!/bin/bash

cd /app/src

# Copy fixed test configuration
mkdir -p "tests"
cp "/tests/meson.build" "tests/meson.build"

# Configure Meson build
mkdir -p build
cd build
meson setup .. -Denable_tests=true 2>&1 || {
    echo "Meson setup failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Build tests (limit parallel jobs to avoid OOM)
meson compile -j 2 2>&1 || {
    echo "Meson compile failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run compiled library tests
meson test spdlog:test_spdlog-utest 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
