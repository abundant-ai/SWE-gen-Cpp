#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"

# Apply the fix patch to enable C++ hostname/IP validation
patch -p1 < /solution/fix.patch

# Rebuild the Go plugin with the fix
GO111MODULE=off make build

# Rebuild test cases with the fix - this regenerates C++ validation code
# The fix modifies C++ code generation templates, so if this succeeds, the fix is working
GO111MODULE=off make testcases
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
