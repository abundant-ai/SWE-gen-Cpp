#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild the protoc-gen-validate plugin after copying the fixed cases.go
make build

# Generate C++ validation code from a test proto with pattern rules
# This tests that pattern validation is correctly implemented in C++ templates
cd tests/harness/cases
mkdir -p cpp
protoc \
    -I . \
    -I ../../.. \
    --cpp_out=cpp \
    --validate_out="lang=cc:cpp" \
    strings.proto

# Check if the generated C++ validator contains RE2 pattern matching code
# The bug removes RE2 support, the fix adds it back
VALIDATOR_FILE="cpp/strings.pb.validate.cc"

# RE2::FullMatch is the key indicator that pattern validation is implemented
if grep -q "RE2::FullMatch" "$VALIDATOR_FILE" 2>/dev/null; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
