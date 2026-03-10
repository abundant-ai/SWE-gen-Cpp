#!/bin/bash

cd /app/src

# Copy the HEAD version of Makefile (with macOS framework linking support)
cp "/tests/Makefile" "test/Makefile"

# Test that macOS Keychain integration is properly implemented
# The fix adds macOS Security framework support for loading system certificates

test_status=0

# Check that httplib.h includes CoreFoundation and Security headers on macOS
if grep -q '#include <CoreFoundation/CoreFoundation.h>' httplib.h && \
   grep -q '#include <Security/Security.h>' httplib.h; then
  echo "✓ PASS: Found CoreFoundation and Security headers for macOS"
else
  echo "✗ FAIL: Missing CoreFoundation or Security headers for macOS"
  test_status=1
fi

# Check that httplib.h has the load_system_certs_on_apple function
if grep -q 'load_system_certs_on_apple' httplib.h; then
  echo "✓ PASS: Found load_system_certs_on_apple function"
else
  echo "✗ FAIL: Missing load_system_certs_on_apple function"
  test_status=1
fi

# Check that CMakeLists.txt links the macOS Security and CoreFoundation frameworks
if grep -q 'framework CoreFoundation' CMakeLists.txt && \
   grep -q 'framework Security' CMakeLists.txt; then
  echo "✓ PASS: Found framework linking for CoreFoundation and Security in CMakeLists.txt"
else
  echo "✗ FAIL: Missing framework linking in CMakeLists.txt"
  test_status=1
fi

# Check that the macOS-specific code is inside proper platform checks
if grep -A2 'defined(__APPLE__)' httplib.h | grep -q 'CoreFoundation'; then
  echo "✓ PASS: macOS headers are properly guarded by __APPLE__ check"
else
  echo "✗ FAIL: macOS headers not properly guarded"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
