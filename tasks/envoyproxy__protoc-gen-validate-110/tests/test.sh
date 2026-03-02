#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/embed.proto" "tests/harness/cases/other_package/embed.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Regenerate test cases from the proto files to pick up changes
make testcases

# Try to compile the generated code package to verify imports are correct
# This will fail in buggy state (BASE) because external enum imports are missing
go build ./tests/harness/cases/go
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
