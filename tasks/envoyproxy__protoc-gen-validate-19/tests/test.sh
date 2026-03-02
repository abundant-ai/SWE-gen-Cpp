#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files if fix has been applied (detected by proto_gen import in pgv_proto_library.bzl)
if grep -q 'load("@com_google_protobuf//:protobuf.bzl", "proto_gen", "cc_proto_library")' bazel/pgv_proto_library.bzl 2>/dev/null; then
mkdir -p "tests/harness"
cp "/tests/harness/BUILD" "tests/harness/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
fi

# Verify pgv_cc_proto_library macro is properly implemented
# Buggy: Simple wrapper that just calls cc_proto_library with validate=1
# Fixed: Full implementation with proto_gen, native.cc_library, and validation header generation
echo "Checking if pgv_cc_proto_library macro is properly implemented..." >&2

# Check 1: bazel/pgv_proto_library.bzl should import proto_gen from @com_google_protobuf
if ! grep -q 'load("@com_google_protobuf//:protobuf.bzl", "proto_gen", "cc_proto_library")' bazel/pgv_proto_library.bzl; then
  echo "BUGGY: bazel/pgv_proto_library.bzl doesn't import proto_gen from @com_google_protobuf" >&2
  test_status=1
# Check 2: pgv_cc_proto_library should have _CcValidateHdrs helper function
elif ! grep -q '_CcValidateHdrs' bazel/pgv_proto_library.bzl; then
  echo "BUGGY: _CcValidateHdrs helper function missing in bazel/pgv_proto_library.bzl" >&2
  test_status=1
# Check 3: pgv_cc_proto_library should call proto_gen for validation code generation
elif ! grep -q 'proto_gen(' bazel/pgv_proto_library.bzl; then
  echo "BUGGY: pgv_cc_proto_library doesn't call proto_gen for validation code generation" >&2
  test_status=1
# Check 4: pgv_cc_proto_library should call native.cc_library to create the validation library
elif ! grep -q 'native.cc_library(' bazel/pgv_proto_library.bzl; then
  echo "BUGGY: pgv_cc_proto_library doesn't call native.cc_library" >&2
  test_status=1
# Check 5: bazel/protobuf.bzl should NOT exist (should use @com_google_protobuf instead)
elif [ -f bazel/protobuf.bzl ]; then
  echo "BUGGY: bazel/protobuf.bzl exists (should use @com_google_protobuf instead)" >&2
  test_status=1
# Check 6: tests/harness/cases/BUILD should use pgv_cc_proto_library for cc target
elif ! grep -q 'pgv_cc_proto_library(' tests/harness/cases/BUILD; then
  echo "BUGGY: tests/harness/cases/BUILD doesn't use pgv_cc_proto_library" >&2
  test_status=1
else
  echo "FIXED: pgv_cc_proto_library macro is properly implemented" >&2
  test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
