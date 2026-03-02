#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch creates windows/bazel.rc, so check for that as a marker
# These test files contain Windows support additions that complete the fix
if [ -f "windows/bazel.rc" ]; then
  mkdir -p "tests/harness/cc"
  cp "/tests/harness/cc/BUILD" "tests/harness/cc/BUILD"
  mkdir -p "tests/harness/cc"
  cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
  mkdir -p "tests/harness/executor"
  cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
  mkdir -p "tests/harness/executor"
  cp "/tests/harness/executor/harness.go" "tests/harness/executor/harness.go"
  mkdir -p "tests/harness/go/main"
  cp "/tests/harness/go/main/BUILD" "tests/harness/go/main/BUILD"
  mkdir -p "tests/harness/gogo/main"
  cp "/tests/harness/gogo/main/BUILD.bazel" "tests/harness/gogo/main/BUILD.bazel"
fi

# Check if Windows-specific configuration exists
# In buggy state (BASE with bug.patch): Windows support removed
# In fixed state (HEAD): Windows support present (after copying test files)

echo "Checking for Windows support in BUILD files and source files..." >&2

# Check for Windows-specific config_setting in tests/harness/cc/BUILD
if grep -q "config_setting" tests/harness/cc/BUILD && grep -q "windows_x86_64" tests/harness/cc/BUILD; then
  echo "FIXED: Found Windows config_setting in tests/harness/cc/BUILD (Windows support present)" >&2
  test_status=0
else
  echo "BUGGY: No Windows config_setting found in tests/harness/cc/BUILD (Windows support removed)" >&2
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
