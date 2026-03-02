#!/bin/bash

cd /app/src

# Set environment variables for leak sanitizer
export LSAN_OPTIONS=suppressions=test/lsan_suppressions.txt

# The PR fixes the Makefile in the repository itself
# The Oracle agent applies fix.patch which updates test/Makefile
# The NOP agent does NOT apply the fix, so test/Makefile remains in buggy state

cd test

# Check if the Makefile contains the correct OPENSSL_SUPPORT line for Darwin
# In the fixed version, it should include both the macro AND the frameworks
if grep -q "OPENSSL_SUPPORT += -DCPPHTTPLIB_USE_CERTS_FROM_MACOSX_KEYCHAIN -framework CoreFoundation -framework Security" Makefile; then
    # Fixed version: Has the macro defined
    # Build and run tests to ensure everything works
    clang++ -o test -I.. -g -std=c++11 -I. -Wall -Wextra -Wtype-limits -Wconversion -Wshadow -DCPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO test.cc gtest/gtest-all.cc gtest/gtest_main.cc -Igtest -DCPPHTTPLIB_OPENSSL_SUPPORT -lssl -lcrypto -DCPPHTTPLIB_ZLIB_SUPPORT -lz -DCPPHTTPLIB_BROTLI_SUPPORT -lbrotlicommon -lbrotlienc -lbrotlidec -DCPPHTTPLIB_ZSTD_SUPPORT -lzstd -lpthread -lcurl -lanl

    ./test --gtest_filter=-*_Online
    test_status=$?
else
    # Buggy version: Missing the macro
    # This is incorrect configuration
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
