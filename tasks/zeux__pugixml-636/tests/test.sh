#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_dom_modify.cpp" "tests/test_dom_modify.cpp"
mkdir -p "tests"
cp "/tests/test_dom_text.cpp" "tests/test_dom_text.cpp"
mkdir -p "tests"
cp "/tests/test_dom_traverse.cpp" "tests/test_dom_traverse.cpp"

# Rebuild with the updated test files using C++17 and PUGIXML_STRING_VIEW to enable string_view support
# Re-apply the compiler warning fixes
sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move/' Makefile
make clean && make cxxstd=c++17 defines=PUGIXML_STRING_VIEW -j$(nproc)
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "Build failed"
  echo 0 > /logs/verifier/reward.txt
  exit $test_status
fi

# Run the test executable
# The test suite will run all tests, including the string_view tests
./build/make-g++-debug-PUGIXML_STRING_VIEW-c++17/test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
