#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/kitchen_sink.proto" "tests/harness/cases/kitchen_sink.proto"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Rebuild protoc-gen-validate to ensure templates compile
GO111MODULE=off make build 2>&1 | tail -50
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# The fix adds support for bytes, repeated, maps, and oneof validation in Python
# We test by checking that the validator.py file contains the necessary template functions
# that were removed in bug.patch and restored in fix.patch

# Check for bytes_template function (validates bytes fields)
if grep -q "def bytes_template" validate/validator.py; then
  test_status=0
else
  test_status=1
fi

# Check for repeated_template function (validates repeated fields)
if [ $test_status -eq 0 ] && grep -q "def repeated_template" validate/validator.py; then
  test_status=0
else
  test_status=1
fi

# Check for map_template function (validates map fields)
if [ $test_status -eq 0 ] && grep -q "def map_template" validate/validator.py; then
  test_status=0
else
  test_status=1
fi

# Check for oneof validation in file_template (validates oneof required fields)
if [ $test_status -eq 0 ] && grep -q "for oneof in p.DESCRIPTOR.oneofs" validate/validator.py; then
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
