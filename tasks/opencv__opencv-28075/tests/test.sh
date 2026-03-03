#!/bin/bash
set -eo pipefail

cd /app/src

# Apply the fix if Oracle agent (has /solution and /tests mounted)
# NOP agent won't have these mounted, so code and tests remain in buggy state
if [ -f "/solution/fix.patch" ]; then
    echo "Applying source fix from /solution..."

    # Check current state - if code is buggy, apply fix normally; if fixed, skip
    if grep -q "class CV_EXPORTS BlackmanWindowLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp; then
        echo "Code already has fix (BlackmanWindowLayer found) - skipping source patch"
    else
        echo "Code is buggy (BlackmanWindowLayer missing) - applying fix.patch"
        if patch -p1 --batch < /solution/fix.patch 2>&1; then
            echo "Source fix applied successfully"
        else
            echo "FAIL: Could not apply source fix patch"
            echo 0 > /logs/verifier/reward.txt
            exit 1
        fi
    fi

    # Also copy the HEAD test files from /tests
    if [ -d "/tests/modules" ]; then
        echo "Copying test files from /tests..."
        cp -r /tests/modules/* modules/
        echo "Test files copied successfully"
    else
        echo "WARN: No /tests directory found"
    fi
else
    echo "No /solution/fix.patch found - running with buggy code (NOP agent)"
fi

# Verify Window Layer state
# The bug.patch removes window layer support (BlackmanWindow, HannWindow, HammingWindow)
# With the bug (BASE), the layers don't exist
# With the fix (HEAD), the layers exist and can be used

# Check if the source file for window layers exists and headers are present
if [ -f "modules/dnn/src/layers/windows_layer.cpp" ] && \
   [ -f "modules/dnn/include/opencv2/dnn/all_layers.hpp" ] && \
   grep -q "class CV_EXPORTS BlackmanWindowLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp && \
   grep -q "class CV_EXPORTS HannWindowLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp && \
   grep -q "class CV_EXPORTS HammingWindowLayer" modules/dnn/include/opencv2/dnn/all_layers.hpp; then
    echo "SUCCESS: Window layer source and headers are present"
    test_status=0
else
    echo "FAIL: Window layer source or headers not found (fix not applied)"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
