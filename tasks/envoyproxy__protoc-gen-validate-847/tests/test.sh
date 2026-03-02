#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/maps.proto" "tests/harness/cases/maps.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild protoc-gen-validate plugin (templates may have changed)
set -x
make build

# Generate test cases with protoc
# This exercises the map validation
make testcases

# Generate the harness protobuf files
make tests/harness/go/harness.pb.go

# Try to build the harness - this will fail if there are compilation errors
echo "=== Building harness executor ==="
cd tests && go build ./harness/executor 2>&1
test_status=$?
cd ..

if [ $test_status -eq 0 ]; then
  echo "=== Build succeeded - map validation is working ==="
else
  echo "=== Build failed - map validation issues ==="
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
