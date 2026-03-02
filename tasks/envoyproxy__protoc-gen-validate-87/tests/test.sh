#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch changes pgv_go_proto_library signature from srcs= to proto=
# Check if the fix has been applied by looking for the proto parameter
if grep -q "def pgv_go_proto_library(name, proto = None" bazel/pgv_proto_library.bzl 2>/dev/null; then
mkdir -p "tests/harness"
cp "/tests/harness/BUILD" "tests/harness/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/BUILD" "tests/harness/cases/other_package/BUILD"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/BUILD" "tests/kitchensink/BUILD"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/any.proto" "tests/kitchensink/any.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/bool.proto" "tests/kitchensink/bool.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/bytes.proto" "tests/kitchensink/bytes.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/disabled.proto" "tests/kitchensink/disabled.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/duration.proto" "tests/kitchensink/duration.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/enum.proto" "tests/kitchensink/enum.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/fixed32.proto" "tests/kitchensink/fixed32.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/fixed64.proto" "tests/kitchensink/fixed64.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/float.proto" "tests/kitchensink/float.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/int32.proto" "tests/kitchensink/int32.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/int64.proto" "tests/kitchensink/int64.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/map.proto" "tests/kitchensink/map.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/message.proto" "tests/kitchensink/message.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/oneof.proto" "tests/kitchensink/oneof.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/repeated.proto" "tests/kitchensink/repeated.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/sfixed32.proto" "tests/kitchensink/sfixed32.proto"
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/sfixed64.proto" "tests/kitchensink/sfixed64.proto"
fi

# Verify the pgv_go_proto_library signature in bazel/pgv_proto_library.bzl
# In buggy state (BASE with bug.patch):
#   - Function signature: def pgv_go_proto_library(name, srcs = None, ...)
#   - Uses srcs parameter (old API)
#   - Loads from :go_proto_library.bzl
# In fixed state (HEAD with fix.patch):
#   - Function signature: def pgv_go_proto_library(name, proto = None, ...)
#   - Uses proto parameter (new API compatible with rules_go)
#   - Loads from @io_bazel_rules_go//proto:def.bzl

echo "Checking pgv_go_proto_library signature in bazel/pgv_proto_library.bzl..." >&2

# Check if the buggy signature (with srcs parameter) is present
if grep -q "def pgv_go_proto_library(name, srcs = None" bazel/pgv_proto_library.bzl; then
  echo "BUGGY: Found old signature with 'srcs' parameter" >&2
  test_status=1
# Check if the fixed signature (with proto parameter) is present
elif grep -q "def pgv_go_proto_library(name, proto = None" bazel/pgv_proto_library.bzl; then
  echo "FIXED: Found new signature with 'proto' parameter" >&2

  # Verify that it loads from new rules_go location
  if grep -q 'load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")' bazel/pgv_proto_library.bzl; then
    echo "FIXED: Correctly loads from @io_bazel_rules_go//proto:def.bzl" >&2
    test_status=0
  else
    echo "ERROR: Should load from @io_bazel_rules_go//proto:def.bzl" >&2
    test_status=1
  fi
else
  echo "ERROR: Cannot find expected function signature" >&2
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
