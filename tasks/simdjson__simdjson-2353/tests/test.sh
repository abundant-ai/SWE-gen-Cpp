#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/ondemand"
cp "/tests/ondemand/ondemand_car_tag_invoke_deserialization.cpp" "tests/ondemand/ondemand_car_tag_invoke_deserialization.cpp"

# Rebuild the specific test executable with the updated test file
if ! cmake --build build --target ondemand_car_tag_invoke_deserialization -j=2; then
  test_status=1
else
  # Run the specific test executable
  ./build/tests/ondemand/ondemand_car_tag_invoke_deserialization
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
