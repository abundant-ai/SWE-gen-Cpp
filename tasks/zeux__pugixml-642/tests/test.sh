#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/autotest-appveyor.ps1" "tests/autotest-appveyor.ps1"

# This PR makes string_view support automatically available when building with C++17.
# In the bug state (BASE), PUGIXML_HAS_STRING_VIEW is NOT defined unless PUGIXML_STRING_VIEW is manually set.
# In the fixed state (HEAD), PUGIXML_HAS_STRING_VIEW IS automatically defined with C++17.

# Create a test program that checks if PUGIXML_HAS_STRING_VIEW is defined
cat > test_string_view_auto.cpp << 'EOF'
#include "src/pugixml.hpp"

#ifndef PUGIXML_HAS_STRING_VIEW
#error "PUGIXML_HAS_STRING_VIEW should be automatically defined when compiling with C++17, but it is not!"
#endif

int main() {
    return 0;
}
EOF

# Try to compile the test with C++17 (no manual PUGIXML_STRING_VIEW define)
# This will FAIL in bug state (error: PUGIXML_HAS_STRING_VIEW not defined)
# This will PASS in fixed state (PUGIXML_HAS_STRING_VIEW is auto-defined)
g++ -std=c++17 test_string_view_auto.cpp -I. -o test_string_view_auto
test_status=$?

if [ $test_status -eq 0 ]; then
  echo "SUCCESS: PUGIXML_HAS_STRING_VIEW is automatically defined with C++17"
  echo 1 > /logs/verifier/reward.txt
else
  echo "FAILURE: PUGIXML_HAS_STRING_VIEW is not automatically defined with C++17"
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
