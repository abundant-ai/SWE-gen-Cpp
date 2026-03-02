#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch removes the srcs parameter and recreates bazel/protobuf.bzl
# Check if the fix has been applied by looking for bazel/protobuf.bzl
if [ -f "bazel/protobuf.bzl" ]; then
  mkdir -p "tests/harness"
  cp "/tests/harness/BUILD" "tests/harness/BUILD"
  mkdir -p "tests/harness/cases"
  cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
  mkdir -p "tests/harness/cases/other_package"
  cp "/tests/harness/cases/other_package/BUILD" "tests/harness/cases/other_package/BUILD"
  mkdir -p "tests/kitchensink"
  cp "/tests/kitchensink/BUILD" "tests/kitchensink/BUILD"
fi

# Verify the pgv_cc_proto_library signature and supporting files
# In buggy state (BASE with bug.patch):
#   - Has srcs parameter in pgv_cc_proto_library (incompatible with newer protobuf)
#   - bazel/protobuf.bzl is deleted
#   - Loads from @com_google_protobuf//:protobuf.bzl
# In fixed state (HEAD):
#   - No srcs parameter (uses deps only, compatible with newer protobuf)
#   - bazel/protobuf.bzl exists
#   - Loads from :protobuf.bzl

echo "Checking for bazel/protobuf.bzl file..." >&2

if [ ! -f "bazel/protobuf.bzl" ]; then
  echo "BUGGY: bazel/protobuf.bzl file is missing (deleted by bug.patch)" >&2
  test_status=1
else
  echo "FIXED: bazel/protobuf.bzl file exists" >&2

  echo "Checking pgv_cc_proto_library signature..." >&2
  # Check if the buggy signature (with srcs parameter) is present
  if grep -A 10 "def pgv_cc_proto_library" bazel/pgv_proto_library.bzl | grep -q "srcs="; then
    echo "BUGGY: Found srcs parameter in pgv_cc_proto_library signature" >&2
    test_status=1
  else
    echo "FIXED: No srcs parameter in pgv_cc_proto_library signature" >&2

    # Verify that it loads from :protobuf.bzl instead of @com_google_protobuf
    if grep -q 'load(":protobuf.bzl", "cc_proto_gen_validate")' bazel/pgv_proto_library.bzl; then
      echo "FIXED: Correctly loads from :protobuf.bzl" >&2
      test_status=0
    else
      echo "ERROR: Should load from :protobuf.bzl" >&2
      test_status=1
    fi
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
