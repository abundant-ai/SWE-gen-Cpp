#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/dom"
cp "/tests/dom/readme_examples.cpp" "tests/dom/readme_examples.cpp"
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_readme_examples.cpp" "tests/ondemand/ondemand_readme_examples.cpp"

# Build and run the readme_examples test executables
test_status=0

# Build dom/readme_examples (COMPILE_ONLY test - just needs to build)
if ! cmake --build build --target readme_examples -j=2; then
  test_status=1
# Build and run ondemand/ondemand_readme_examples
elif ! cmake --build build --target ondemand_readme_examples -j=2; then
  test_status=1
elif ! ./build/tests/ondemand/ondemand_readme_examples; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
