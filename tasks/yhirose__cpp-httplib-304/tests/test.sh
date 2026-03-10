#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state with fixed version)
cp "/tests/test.cc" "test/test.cc"
cp "/tests/www/dir/test.abcde" "test/www/dir/test.abcde"

cd test

test_status=0

# Generate certificates for tests (required by Makefile)
openssl genrsa 2048 > key.pem 2>/dev/null
openssl req -new -batch -config test.conf -key key.pem | openssl x509 -days 3650 -req -signkey key.pem > cert.pem 2>/dev/null
openssl req -x509 -config test.conf -key key.pem -sha256 -days 3650 -nodes -out cert2.pem -extensions SAN 2>/dev/null
openssl genrsa 2048 > rootCA.key.pem 2>/dev/null
openssl req -x509 -new -batch -config test.rootCA.conf -key rootCA.key.pem -days 1024 > rootCA.cert.pem 2>/dev/null
openssl genrsa 2048 > client.key.pem 2>/dev/null
openssl req -new -batch -config test.conf -key client.key.pem | openssl x509 -days 370 -req -CA rootCA.cert.pem -CAkey rootCA.key.pem -CAcreateserial > client.cert.pem 2>/dev/null

# Build and run the test
echo "Building and running test..."
if make test 2>&1; then
  echo "✓ PASS: Test succeeded"
else
  echo "✗ FAIL: Test failed"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
