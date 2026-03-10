#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness"
cp "/tests/harness/BUILD" "tests/harness/BUILD"
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/BUILD" "tests/harness/cc/BUILD"

# The test verifies that BUILD files correctly load cc_proto_library from
# @com_google_protobuf//bazel:cc_proto_library.bzl instead of @rules_cc//cc:defs.bzl
#
# The bug is that the BUILD files incorrectly try to load cc_proto_library from
# @rules_cc//cc:defs.bzl, which doesn't exist in newer versions of rules_cc.
#
# In the buggy state (BASE):
#   - tests/harness/BUILD loads cc_proto_library from @rules_cc//cc:defs.bzl
#   - tests/harness/cc/BUILD loads cc_proto_library from @rules_cc//cc:defs.bzl
#   - validate/BUILD loads cc_proto_library from @rules_cc//cc:defs.bzl
#   - bazel/pgv_proto_library.bzl uses native.cc_proto_library
#
# In the fixed state (BASE + fix.patch):
#   - tests/harness/BUILD loads cc_proto_library from @com_google_protobuf//bazel:cc_proto_library.bzl
#   - tests/harness/cc/BUILD loads cc_proto_library from @com_google_protobuf//bazel:cc_proto_library.bzl
#   - validate/BUILD loads cc_proto_library from @com_google_protobuf//bazel:cc_proto_library.bzl
#   - bazel/pgv_proto_library.bzl uses cc_proto_library from @com_google_protobuf//bazel:cc_proto_library.bzl

echo "Testing if BUILD files correctly load cc_proto_library from @com_google_protobuf..." >&2

# Check if tests/harness/BUILD has the correct import
if grep -q '@com_google_protobuf//bazel:cc_proto_library.bzl' tests/harness/BUILD && \
   ! grep -q 'load("@rules_cc//cc:defs.bzl".*cc_proto_library' tests/harness/BUILD; then
    echo "FIXED: tests/harness/BUILD correctly loads cc_proto_library from @com_google_protobuf" >&2
    has_harness_fix=1
else
    echo "BUGGY: tests/harness/BUILD incorrectly loads cc_proto_library from @rules_cc" >&2
    has_harness_fix=0
fi

# Check if tests/harness/cc/BUILD has the correct import
if grep -q '@com_google_protobuf//bazel:cc_proto_library.bzl' tests/harness/cc/BUILD && \
   ! grep -q 'load("@rules_cc//cc:defs.bzl".*cc_proto_library' tests/harness/cc/BUILD; then
    echo "FIXED: tests/harness/cc/BUILD correctly loads cc_proto_library from @com_google_protobuf" >&2
    has_cc_fix=1
else
    echo "BUGGY: tests/harness/cc/BUILD incorrectly loads cc_proto_library from @rules_cc" >&2
    has_cc_fix=0
fi

# Check if validate/BUILD has the correct import
if grep -q '@com_google_protobuf//bazel:cc_proto_library.bzl' validate/BUILD 2>/dev/null && \
   ! grep -q 'load("@rules_cc//cc:defs.bzl".*cc_proto_library' validate/BUILD 2>/dev/null; then
    echo "FIXED: validate/BUILD correctly loads cc_proto_library from @com_google_protobuf" >&2
    has_validate_fix=1
else
    echo "BUGGY: validate/BUILD incorrectly loads cc_proto_library from @rules_cc" >&2
    has_validate_fix=0
fi

# Check if bazel/pgv_proto_library.bzl has the correct import
if grep -q '@com_google_protobuf//bazel:cc_proto_library.bzl' bazel/pgv_proto_library.bzl 2>/dev/null && \
   grep -q 'cc_proto_library(' bazel/pgv_proto_library.bzl 2>/dev/null && \
   ! grep -q 'native.cc_proto_library' bazel/pgv_proto_library.bzl 2>/dev/null; then
    echo "FIXED: bazel/pgv_proto_library.bzl correctly uses cc_proto_library from @com_google_protobuf" >&2
    has_pgv_fix=1
else
    echo "BUGGY: bazel/pgv_proto_library.bzl uses native.cc_proto_library" >&2
    has_pgv_fix=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_harness_fix -eq 1 ] && [ $has_cc_fix -eq 1 ] && [ $has_validate_fix -eq 1 ] && [ $has_pgv_fix -eq 1 ]; then
    echo "PASS: All BUILD files correctly load cc_proto_library from @com_google_protobuf" >&2
    test_status=0
else
    echo "FAIL: Some BUILD files still incorrectly load cc_proto_library from @rules_cc" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
