#!/bin/bash

cd /app/src

export CI=true

# PR #327 fixes Bazel 1.0+ compatibility issues with virtual imports
# The bug: Bazel code uses simple _proto_path which doesn't handle virtual imports correctly
# The fix: Uses proper _path_ignoring_repository that handles _virtual_imports directories

echo "Testing PR #327 fixes for Bazel 1.0+ compatibility..." >&2

# Test 1: Check if protobuf.bzl uses the proper _path_ignoring_repository function
echo "Checking if protobuf.bzl uses _path_ignoring_repository function..." >&2
if grep -q "def _path_ignoring_repository(f):" bazel/protobuf.bzl && \
   grep -q "_virtual_imports" bazel/protobuf.bzl && \
   grep -q "_path_ignoring_repository(proto)" bazel/protobuf.bzl; then
    echo "PASS: protobuf.bzl uses _path_ignoring_repository function with virtual imports support" >&2
    has_path_ignoring=1
else
    echo "FAIL: protobuf.bzl uses simple _proto_path without virtual imports support" >&2
    has_path_ignoring=0
fi

# Test 2: Check if pgv_proto_library.bzl loads from @rules_cc
echo "Checking if pgv_proto_library.bzl loads from @rules_cc..." >&2
if grep -q 'load("@rules_cc//cc:defs.bzl", "cc_library")' bazel/pgv_proto_library.bzl; then
    echo "PASS: pgv_proto_library.bzl loads cc_library from @rules_cc" >&2
    has_rules_cc=1
else
    echo "FAIL: pgv_proto_library.bzl uses native.cc_library" >&2
    has_rules_cc=0
fi

# Test 3: Check if pgv_proto_library.bzl loads from @rules_python
echo "Checking if pgv_proto_library.bzl loads from @rules_python..." >&2
if grep -q 'load("@rules_python//python:defs.bzl", "py_library")' bazel/pgv_proto_library.bzl; then
    echo "PASS: pgv_proto_library.bzl loads py_library from @rules_python" >&2
    has_rules_python=1
else
    echo "FAIL: pgv_proto_library.bzl uses native.py_library" >&2
    has_rules_python=0
fi

# Test 4: Check if repositories.bzl has updated versions
echo "Checking if repositories.bzl has updated dependency versions..." >&2
if grep -q "rules_go-v0.22.2" bazel/repositories.bzl && \
   grep -q "protobuf-3.11.4" bazel/repositories.bzl; then
    echo "PASS: repositories.bzl has updated versions" >&2
    has_updated_deps=1
else
    echo "FAIL: repositories.bzl has old dependency versions" >&2
    has_updated_deps=0
fi

# Test 5: Check if Java BUILD files load from @rules_java
echo "Checking if Java library BUILD files load from @rules_java..." >&2
if grep -q 'load("@rules_java//java:defs.bzl"' java/pgv-java-stub/src/main/java/io/envoyproxy/pgv/BUILD && \
   grep -q 'load("@rules_java//java:defs.bzl"' java/pgv-java-validation/src/main/java/io/envoyproxy/pgv/BUILD; then
    echo "PASS: Java library BUILD files load from @rules_java" >&2
    has_build_rules_java=1
else
    echo "FAIL: Java library BUILD files don't load from @rules_java" >&2
    has_build_rules_java=0
fi

# All checks must pass
if [ $has_path_ignoring -eq 1 ] && [ $has_rules_cc -eq 1 ] && [ $has_rules_python -eq 1 ] && \
   [ $has_updated_deps -eq 1 ] && [ $has_build_rules_java -eq 1 ]; then
    echo "PASS: All PR #327 fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some PR #327 fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
