#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/video/test"
cp "/tests/modules/video/test/test_bgfg2.cpp" "modules/video/test/test_bgfg2.cpp"

# Check if the knownForegroundMask overload exists in the header file
# In BASE state (buggy), this overload is removed
# In HEAD state (fixed), the overload is present
if grep -q 'virtual void apply(InputArray image, InputArray knownForegroundMask, OutputArray fgmask, double learningRate=-1)' modules/video/include/opencv2/video/background_segm.hpp; then
    echo "PASS: knownForegroundMask overload present in header (fixed version)"
    test_status=0
else
    echo "FAIL: knownForegroundMask overload missing from header (buggy version)" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
