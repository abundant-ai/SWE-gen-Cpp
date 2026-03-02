#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/strings.proto" "tests/harness/cases/strings.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Regenerate test cases from the updated proto files (limit output to avoid buffer overflow)
GO111MODULE=off make testcases 2>&1 | head -100
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Build harness proto for go
cd tests/harness && protoc -I . --go_out="Mvalidate/validate.proto=github.com/envoyproxy/protoc-gen-validate/validate,Mgoogle/protobuf/any.proto=github.com/golang/protobuf/ptypes/any,Mgoogle/protobuf/duration.proto=github.com/golang/protobuf/ptypes/duration,Mgoogle/protobuf/struct.proto=github.com/golang/protobuf/ptypes/struct,Mgoogle/protobuf/timestamp.proto=github.com/golang/protobuf/ptypes/timestamp,Mgoogle/protobuf/wrappers.proto=github.com/golang/protobuf/ptypes/wrappers,Mgoogle/protobuf/descriptor.proto=github.com/golang/protobuf/protoc-gen-go/descriptor,Mgogoproto/gogo.proto=github.com/envoyproxy/protoc-gen-validate/gogoproto:./go" harness.proto
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

# Build the go harness
go build -o tests/harness/go/main/go-harness ./tests/harness/go/main

# Build the executor (includes cases.go)
cd tests/harness/executor
go build -o executor *.go
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

# Run the harness tests for Go only (which test the string validation including HTTP headers)
tests/harness/executor/executor -go
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
