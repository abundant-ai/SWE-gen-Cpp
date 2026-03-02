#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
mkdir -p "tests/harness/go"
cp "/tests/harness/go/harness.go" "tests/harness/go/harness.go"

# The test verifies that the Bazel build system properly links validation dependencies
#
# The bug is in bazel/go_proto_library.bzl which doesn't add _WELL_KNOWN_PTYPES dependency
# when validate=true, causing validation code to not be linked in Bazel builds.
#
# The test files from HEAD (tests/harness/*/BUILD, tests/harness/go/harness.go) expect
# validation to work properly. They have:
#   - tests/harness/executor/BUILD with deps on "//tests/harness/cases:go" and "//tests/harness/go:go-harness"
#   - tests/harness/cases/BUILD with importpath for proper package resolution
#   - tests/harness/go/harness.go with direct type assertion (fails loudly if Validate() missing)
#
# In the buggy state (BASE):
#   - bazel/go_proto_library.bzl is missing _WELL_KNOWN_PTYPES definition and usage
#   - Bazel builds won't link validation code properly even with correct test files
# In the fixed state (BASE + fix.patch):
#   - bazel/go_proto_library.bzl has _WELL_KNOWN_PTYPES and adds it to dependencies when validate=true
#   - Bazel builds will properly link validation code

echo "Testing if bazel/go_proto_library.bzl has validation linking fix..." >&2

# Check if bazel/go_proto_library.bzl has the _WELL_KNOWN_PTYPES definition
if grep -F '_WELL_KNOWN_PTYPES = _PROTOBUF_REPO + "//ptypes:"' bazel/go_proto_library.bzl >/dev/null 2>&1; then
    echo "FIXED: bazel/go_proto_library.bzl defines _WELL_KNOWN_PTYPES" >&2
    has_ptypes_def=1
else
    echo "BUGGY: bazel/go_proto_library.bzl missing _WELL_KNOWN_PTYPES definition" >&2
    has_ptypes_def=0
fi

# Check if bazel/go_proto_library.bzl adds _WELL_KNOWN_PTYPES to go_lib_deps
if grep -F 'go_lib_deps += [_WELL_KNOWN_PTYPES]' bazel/go_proto_library.bzl >/dev/null 2>&1; then
    echo "FIXED: bazel/go_proto_library.bzl adds _WELL_KNOWN_PTYPES to deps" >&2
    has_ptypes_usage=1
else
    echo "BUGGY: bazel/go_proto_library.bzl doesn't add _WELL_KNOWN_PTYPES to deps" >&2
    has_ptypes_usage=0
fi

# Test passes if both checks pass (meaning fix is present)
if [ $has_ptypes_def -eq 1 ] && [ $has_ptypes_usage -eq 1 ]; then
    echo "PASS: Bazel validation linking fix is present" >&2
    test_status=0
else
    echo "FAIL: Bazel validation linking fix is missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
