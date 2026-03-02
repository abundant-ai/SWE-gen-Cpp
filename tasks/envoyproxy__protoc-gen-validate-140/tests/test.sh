#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Apply the fix patch to enable repeated/map enum validation in C++
patch -p1 < /solution/fix.patch

# Rebuild the Go plugin with the fix
GO111MODULE=off make build

# Try to generate C++ validation code for the updated enums.proto
# Without the fix, this will crash with nil pointer dereference when processing repeated enum fields
mkdir -p tests/harness/cases/cc
cd tests/harness/cases && \
protoc \
  -I . \
  -I ../../.. \
  --validate_out="lang=cc:./cc" \
  enums.proto

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
