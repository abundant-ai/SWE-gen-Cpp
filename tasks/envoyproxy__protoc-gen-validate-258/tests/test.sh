#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy the corrected BUILD file from /tests (the agent needs to have fixed the WORKSPACE)
mkdir -p "tests/harness/python"
cp "/tests/harness/python/BUILD" "tests/harness/python/BUILD"

# The fix reverts the Bazel dependency setup
# The bug.patch changed the WORKSPACE to use direct repository rules and @my_deps
# The fix.patch reverts it back to use macro-based deps and @pgv_pip_deps
# We test by checking that the BUILD file and WORKSPACE contain the correct configuration

# Check for the fixed import name @pgv_pip_deps in the BUILD file
if grep -q '@pgv_pip_deps//:requirements.bzl' tests/harness/python/BUILD; then
  test_status=0
else
  test_status=1
fi

# Also check that WORKSPACE uses the macro-based approach
if [ $test_status -eq 0 ] && grep -q 'pgv_dependencies()' WORKSPACE; then
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
