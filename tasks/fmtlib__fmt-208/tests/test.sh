#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/format-test.cc" "test/format-test.cc"

# The bug is that iostream support cannot be disabled with FMT_NO_STREAM_LIBRARIES
# The fix properly guards iostream functionality so it can be disabled
# Test by checking if the print(ostream) function is declared when FMT_NO_STREAM_LIBRARIES is defined
cat > /tmp/test_no_stream.cc << 'EOF'
#define FMT_NO_STREAM_LIBRARIES
#include "format.h"
#include <sstream>  // Manually include sstream for the test

int main() {
  std::ostringstream os;
  // This function should NOT be available when FMT_NO_STREAM_LIBRARIES is defined
  // If the bug is present, this will compile. If the fix is applied, this will fail.
  fmt::print(os, "test {}", 123);
  return 0;
}
EOF

# Try to compile the test program
g++ -std=c++11 -I. -c /tmp/test_no_stream.cc -o /tmp/test_no_stream.o 2>&1
compile_status=$?

if [ $compile_status -ne 0 ]; then
  # Compilation failed - the fix is working (print(ostream) is properly guarded)
  echo "SUCCESS: print(ostream) is not available with FMT_NO_STREAM_LIBRARIES defined"
  test_status=0
else
  # Compilation succeeded - the bug is present (print(ostream) is still available)
  echo "ERROR: print(ostream) should not be available with FMT_NO_STREAM_LIBRARIES defined"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
