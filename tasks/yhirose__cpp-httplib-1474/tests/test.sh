#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Makefile" "test/Makefile"

# Check if httplib.h contains the macOS Keychain support code
# In the fixed version, httplib.h should include CoreFoundation/CoreFoundation.h and Security/Security.h
# In the buggy version, these includes will NOT be present
if grep -q "#include <CoreFoundation/CoreFoundation.h>" httplib.h && \
   grep -q "#include <Security/Security.h>" httplib.h && \
   grep -q "load_system_certs_on_apple" httplib.h; then
    # Fixed version: has the macOS Keychain support code
    test_status=0
else
    # Buggy version: missing the macOS Keychain support
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
