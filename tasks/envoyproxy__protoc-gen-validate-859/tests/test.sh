#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/sort"
cp "/tests/harness/cases/sort/BUILD" "tests/harness/cases/sort/BUILD"
mkdir -p "tests/harness/cases/sort"
cp "/tests/harness/cases/sort/sort.proto" "tests/harness/cases/sort/sort.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/go/main"
cp "/tests/harness/go/main/BUILD" "tests/harness/go/main/BUILD"

# Rebuild protoc-gen-validate plugin (templates/goshared/register.go may have changed)
set -x
make build

# Generate test cases with protoc
# This exercises the enum validation with the sort package
# The fix resolves the name collision between Go's "sort" package and the generated "sort" package
make testcases

# Generate the harness protobuf files
make tests/harness/go/harness.pb.go

# Try to build the harness - this will fail if there's a name collision
echo "=== Building harness executor ==="
cd tests && go build ./harness/executor 2>&1
test_status=$?
cd ..

if [ $test_status -eq 0 ]; then
  echo "=== Build succeeded - sort package name collision is resolved ==="
else
  echo "=== Build failed - sort package name collision still exists ==="
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
