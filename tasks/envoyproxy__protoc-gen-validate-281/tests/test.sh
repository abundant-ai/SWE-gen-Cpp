#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild the protoc-gen-validate plugin after copying the fixed files
make build

# Generate C++ validation code from maps.proto
# This tests that map validation with recursive message values is correctly implemented in C++ templates
cd tests/harness/cases
mkdir -p cpp
protoc \
    -I . \
    -I ../../.. \
    --cpp_out=cpp \
    --validate_out="lang=cc:cpp" \
    maps.proto

# Check if the generated C++ validator contains map iteration and validation code
# The bug makes map validation throw "unimplemented", the fix properly iterates and validates
VALIDATOR_FILE="cpp/maps.pb.validate.cc"

# Look for "for (const auto& kv" which is the C++ map iteration pattern
# With the bug, the template throws UnimplementedException instead of generating iteration code
# With the fix, it generates proper map iteration and validation
if grep -q "for (const auto& kv" "$VALIDATOR_FILE" 2>/dev/null; then
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
