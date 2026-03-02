#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Copy the corrected test files from /tests (overwrites BASE state)
mkdir -p "tests/harness"
cp "/tests/harness/BUILD" "tests/harness/BUILD"
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
cp "/tests/harness/cases/kitchen_sink.proto" "tests/harness/cases/kitchen_sink.proto"
mkdir -p "tests/harness/cases/other_package"
cp "/tests/harness/cases/other_package/BUILD" "tests/harness/cases/other_package/BUILD"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
cp "/tests/harness/executor/executor.go" "tests/harness/executor/executor.go"
cp "/tests/harness/executor/harness.go" "tests/harness/executor/harness.go"
cp "/tests/harness/executor/worker.go" "tests/harness/executor/worker.go"
mkdir -p "tests/harness/python"
cp "/tests/harness/python/BUILD" "tests/harness/python/BUILD"
cp "/tests/harness/python/harness.py" "tests/harness/python/harness.py"

# The fix adds Python support to the Bazel build system by:
# 1. Adding Python dependencies to WORKSPACE (@my_deps)
# 2. Adding the pgv_python_proto_library function to bazel/pgv_proto_library.bzl
# 3. Updating Makefile to include -python flag and --incompatible_new_actions_api=false

# Check for the Python dependencies in WORKSPACE
if grep -q '@my_deps//:requirements.bzl' WORKSPACE && grep -q 'pip_import' WORKSPACE; then
  test_status=0
else
  test_status=1
fi

# Check for the pgv_python_proto_library function in bazel/pgv_proto_library.bzl
if [ $test_status -eq 0 ] && grep -q 'def pgv_python_proto_library' bazel/pgv_proto_library.bzl && \
   grep -q 'python_proto_gen_validate' bazel/pgv_proto_library.bzl; then
  test_status=0
else
  test_status=1
fi

# Check for the Makefile changes (--incompatible_new_actions_api=false and -python flag)
if [ $test_status -eq 0 ] && grep -q -- '--incompatible_new_actions_api=false' Makefile && \
   grep -q -- '-python' Makefile; then
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
