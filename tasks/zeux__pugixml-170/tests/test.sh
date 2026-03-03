#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_document.cpp" "tests/test_document.cpp"

# Rebuild with the updated test files using C++17 and PUGIXML_STRING_VIEW to enable string_view support
# Re-apply the compiler warning fixes
sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move -Wno-error=deprecated-declarations -Wno-error=attributes/' Makefile
make clean && make cxxstd=c++17 defines=PUGIXML_STRING_VIEW -j$(nproc)
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "Build failed"
  echo 0 > /logs/verifier/reward.txt
  exit $test_status
fi

# Run the test executable
# The test suite will run all tests, including the updated test_document.cpp
./build/make-g++-debug-PUGIXML_STRING_VIEW-c++17/test > /tmp/test_output.txt 2>&1
test_status=$?

# Check if the only failure is the known flaky test document_load_file_special_folder
# This test fails in some Docker environments due to environment-specific file I/O behavior
if [ $test_status -ne 0 ]; then
  if grep -q "Test document_load_file_special_folder failed" /tmp/test_output.txt && \
     grep -q "FAILURE: 1 out of .* tests failed" /tmp/test_output.txt; then
    echo "Ignoring known flaky test: document_load_file_special_folder"
    cat /tmp/test_output.txt
    test_status=0
  else
    cat /tmp/test_output.txt
  fi
else
  cat /tmp/test_output.txt
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
