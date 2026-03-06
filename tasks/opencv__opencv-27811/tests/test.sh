#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/imgcodecs/test"
cp "/tests/modules/imgcodecs/test/test_bmp.cpp" "modules/imgcodecs/test/test_bmp.cpp"

# Check if the 1GB limit assertion exists in the BMP decoder
# In BASE state (buggy), this assertion is present and blocks >1GB images
# In HEAD state (fixed), the assertion is removed to support >1GB images
if grep -q 'BMP reader implementation doesn'"'"'t support large images >= 1Gb' modules/imgcodecs/src/grfmt_bmp.cpp; then
    echo "FAIL: 1GB assertion still present in BMP decoder (buggy version)" >&2
    test_status=1
else
    echo "PASS: 1GB assertion removed from BMP decoder (fixed version)"
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
