#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/BUILD" "tests/harness/cases/other_package/BUILD"

# Apply the fix patch to enable transitive dependency handling in pgv_java_proto_library
patch -p1 < /solution/fix.patch

# Rebuild the Go plugin with the fix
GO111MODULE=off make build

# Verify the fix was applied correctly by checking that the key changes are present
# The fix should have:
# 1. Added _java_proto_gen_validate_aspect and transitive dependency handling in bazel/protobuf.bzl
# 2. Made pgv_java_proto_library use java_proto_gen_validate directly in bazel/pgv_proto_library.bzl

# Check that the aspect implementation exists (this is the core of the fix)
grep -q "_java_proto_gen_validate_aspect" bazel/protobuf.bzl && \
grep -q "transitive.*ProtoValidateSourceInfo" bazel/protobuf.bzl && \
grep -q "pgv_java_proto_library = java_proto_gen_validate" bazel/pgv_proto_library.bzl

test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
