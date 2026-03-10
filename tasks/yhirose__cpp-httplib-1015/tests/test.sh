#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"
cp "/tests/include_httplib.cc" "test/include_httplib.cc"

# Test the split build mode by attempting to build with the split Makefile
# The fix ensures that template definitions are available in the header for split builds

cd test

test_status=0

# Generate certificate for tests (required by Makefile)
openssl genrsa 2048 > key.pem 2>/dev/null
openssl req -new -batch -subj "/C=US/ST=Test/L=Test/O=Test/CN=test" -key key.pem | openssl x509 -days 3650 -req -signkey key.pem > cert.pem 2>/dev/null

# Try to build the split test (test_split target)
# This will fail if template definitions are not in the header
echo "Building split test..."
if make test_split 2>&1; then
  echo "✓ PASS: Split build succeeded"
else
  echo "✗ FAIL: Split build failed (template definitions not accessible)"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
