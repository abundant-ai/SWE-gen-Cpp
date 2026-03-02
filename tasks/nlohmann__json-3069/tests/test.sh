#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/src"
cp "/tests/src/unit-diagnostics.cpp" "test/src/unit-diagnostics.cpp"
mkdir -p "test/src"
cp "/tests/src/unit-modifiers.cpp" "test/src/unit-modifiers.cpp"

# Rebuild the test executables with the updated test files
if ! cmake --build build --target test-diagnostics; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

if ! cmake --build build --target test-modifiers; then
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run the specific test executables for unit-diagnostics.cpp
./build/test/test-diagnostics
test_status_diagnostics=$?

# Run the specific test executables for unit-modifiers.cpp
./build/test/test-modifiers
test_status_modifiers=$?

# Both tests must pass
test_status=$((test_status_diagnostics | test_status_modifiers))

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
