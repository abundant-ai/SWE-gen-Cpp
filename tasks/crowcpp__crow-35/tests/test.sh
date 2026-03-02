#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/template"
cp "/tests/template/test.py" "tests/template/test.py"

# Clean and rebuild the mustachetest executable to ensure all changes are picked up
cd build
rm -f tests/template/mustachetest tests/template/mustachetest.o tests/template/CMakeFiles/mustachetest.dir/mustachetest.cpp.o
cmake .. -DCROW_BUILD_TESTS=ON -DCROW_ENABLE_SSL=ON
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

cmake --build . --target mustachetest --clean-first
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build template_test_copy target to copy test.py to build directory
cmake --build . --target template_test_copy
build_status=$?

if [ $build_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the test.py Python script which uses the mustachetest executable
cd tests/template || exit 1
timeout 30 python3 test.py
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
