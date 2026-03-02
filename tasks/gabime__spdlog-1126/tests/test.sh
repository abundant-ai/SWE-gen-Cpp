#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/meson.build" "tests/meson.build"

# Build with Meson to verify the tests/meson.build file is valid
rm -rf builddir
meson setup builddir || {
    echo "Meson setup failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

meson compile -C builddir 2>&1 || {
    echo "Build failed"
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the tests using Meson
meson test -C builddir
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
