#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Regenerate test cases from the updated proto files (limit output to avoid buffer overflow)
GO111MODULE=off make testcases 2>&1 | head -100
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Test Java compilation of generated validators for maps
# The bug causes Java compilation to fail for map key/value validation with certain numeric types
# We just need to compile the test classes to verify the generated Java code is valid
cd java && mvn clean test-compile 2>&1 | tail -50
test_status=${PIPESTATUS[0]}

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
