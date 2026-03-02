#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/python"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# Rebuild protoc-gen-validate plugin (templates may have changed)
set -x
make build

# Test that the Python validator can import validate_all successfully
# This will fail if validate_all is not implemented or has import errors
python3 -c "from python.protoc_gen_validate.validator import validate, validate_all, ValidationFailed; print('validate_all import successful')"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
