#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/go.mod" "tests/go.mod"
mkdir -p "tests"
cp "/tests/go.sum" "tests/go.sum"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/embed.proto" "tests/harness/cases/other_package/embed.proto"
mkdir -p "tests/harness/cases/yet_another_package"
cp "/tests/harness/cases/yet_another_package/embed.proto" "tests/harness/cases/yet_another_package/embed.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Rebuild protoc-gen-validate plugin (templates may have changed)
set -x
make build

# Generate test cases with protoc
# This exercises the enum validation
make testcases

# Generate the harness protobuf files
make tests/harness/go/harness.pb.go

# Try to build the harness - this will fail if there are compilation errors
echo "=== Building harness executor ==="
cd tests && go build ./harness/executor 2>&1
test_status=$?
cd ..

if [ $test_status -eq 0 ]; then
  echo "=== Build succeeded - enum validation is working ==="
else
  echo "=== Build failed - enum validation issues ==="
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
