#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/filename-with-dash.proto" "tests/harness/cases/filename-with-dash.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Rebuild the protoc-gen-validate plugin after copying the fixed files
make build

# Generate C++ validation code from filename-with-dash.proto
# This tests that filenames with dashes produce valid C++ macro identifiers
cd tests/harness/cases
mkdir -p cpp
protoc \
    -I . \
    -I ../../.. \
    --cpp_out=cpp \
    --validate_out="lang=cc:cpp" \
    filename-with-dash.proto

# Check if the generated C++ validator contains proper macro names
# The bug makes macros like FILENAME-WITH-DASH_PB_VALIDATE_H (invalid - has dashes)
# The fix converts to FILENAME_WITH_DASH_PB_VALIDATE_H (valid - underscores only)
VALIDATOR_HEADER="cpp/filename-with-dash.pb.validate.h"
VALIDATOR_SOURCE="cpp/filename-with-dash.pb.validate.cc"

# Check for proper macro naming (underscores, not dashes) in both files
# With the fix, all macro identifiers should use underscores
if [ -f "$VALIDATOR_HEADER" ] && [ -f "$VALIDATOR_SOURCE" ]; then
    # If either file contains FILENAME-WITH-DASH (with dash), the bug is present
    if grep -q "FILENAME-WITH-DASH" "$VALIDATOR_HEADER" "$VALIDATOR_SOURCE" 2>/dev/null; then
        echo "FAIL: Found invalid macro names with dashes"
        test_status=1
    # If files contain FILENAME_WITH_DASH (with underscore), the fix is working
    elif grep -q "FILENAME_WITH_DASH" "$VALIDATOR_HEADER" "$VALIDATOR_SOURCE" 2>/dev/null; then
        echo "PASS: Generated C++ uses proper macro names with underscores"
        test_status=0
    else
        echo "FAIL: Could not verify macro naming"
        test_status=1
    fi
else
    echo "FAIL: Generated C++ files not found"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
