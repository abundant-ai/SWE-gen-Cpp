#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"

# Generate Java validation code from the proto file
# This is where the bug manifests: with sint64 map keys, the buggy template
# will generate Java code with long literals missing the "L" suffix

# First, ensure we have the protoc-gen-validate plugin built
make build

# Generate Java code for the maps.proto test case
cd tests/harness/cases
mkdir -p java
protoc \
    -I . \
    -I ../../.. \
    --java_out=java \
    --validate_out="lang=java:java" \
    maps.proto

# Check if the generated validator contains correct "L" suffix for long literals
# The bug causes it to generate "private final long MapKeysLt = 0;" (missing L suffix)
# The fix generates "= 0L;" (with L suffix for long literals)
cd java

# Java protoc creates package directories based on proto package name
VALIDATOR_FILE="tests/harness/cases/MapsValidator.java"

# Check if the generated code has the correct L suffix for long literals
if grep -q "= 0L;" "$VALIDATOR_FILE" 2>/dev/null; then
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
