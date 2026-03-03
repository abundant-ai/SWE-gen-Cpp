#!/bin/bash

cd /app/src

# Initialize test_status
test_status=0

# The fix adds compiler intrinsic-based regex detection to src/re.h
# The bug was that regex selection depended on per-target compile flags (have_regex_copts),
# which could lead to ODR violations when different targets had different flags.
# The fix detects the regex engine using compiler intrinsics in the header directly.

# Validate src/re.h - the fixed version should have the automatic regex detection code
if grep -q "No explicit regex selection" src/re.h; then
    echo "✓ src/re.h has compiler intrinsic-based regex detection (fix applied)"
    test_status=0
else
    echo "✗ src/re.h is missing regex detection code (buggy state)"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
