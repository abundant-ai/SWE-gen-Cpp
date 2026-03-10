#!/bin/bash

cd /go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/strings.proto" "tests/harness/cases/strings.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Regenerate test cases after changes (picks up any modifications to proto files)
make testcases

# Build harness proto and test harnesses
make tests/harness/go/harness.pb.go
make tests/harness/go/main/go-harness
make tests/harness/gogo/main/go-harness

# Run the test harness with Go support
# This tests the string validation rules (from strings.proto) through the Go harness
go run ./tests/harness/executor/*.go -go
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
