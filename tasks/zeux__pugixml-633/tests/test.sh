#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/test_dom_modify.cpp" "tests/test_dom_modify.cpp"
mkdir -p "tests"
cp "/tests/test_dom_text.cpp" "tests/test_dom_text.cpp"

# Create a compile-time test to verify PUGIXML_HAS_STRING_VIEW is defined
# This will fail to compile in the BASE state where string_view support is missing
cat > /tmp/test_stringview_support.cpp << 'EOF'
#include "src/pugixml.hpp"

#ifndef PUGIXML_HAS_STRING_VIEW
#error "PUGIXML_HAS_STRING_VIEW is not defined - string_view support is missing!"
#endif

int main() {
    // Test that string_view_t typedef exists
    pugi::string_view_t sv("test", 4);
    return 0;
}
EOF

# Try to compile the test
g++ /tmp/test_stringview_support.cpp -I. -std=c++17 -D PUGIXML_STRING_VIEW -o /tmp/test_stringview_support 2>&1
if [ $? -ne 0 ]; then
  echo "String_view support validation failed - PUGIXML_HAS_STRING_VIEW is not properly defined"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

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
