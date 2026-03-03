#!/bin/bash

cd /app/src

# Initialize test_status
test_status=0

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD" "test/BUILD"

# This PR adds Bazel support files. The fix.patch should restore WORKSPACE and bazel/* files.
# The test/BUILD file (copied above) completes the Bazel configuration.
# We verify all necessary Bazel files exist and are valid.

# Check if WORKSPACE exists (should be created by fix.patch)
if [ ! -f "WORKSPACE" ]; then
    echo "ERROR: WORKSPACE file does not exist! Fix patch may not have been applied." >&2
    test_status=1
fi

# Check if bazel/have_regex.bzl exists (should be created by fix.patch)
if [ $test_status -eq 0 ]; then
    if [ ! -f "bazel/have_regex.bzl" ]; then
        echo "ERROR: bazel/have_regex.bzl does not exist! Fix patch may not have been applied." >&2
        test_status=1
    fi
fi

# Check if test/BUILD exists (copied from /tests above)
if [ $test_status -eq 0 ]; then
    if [ ! -f "test/BUILD" ]; then
        echo "ERROR: test/BUILD file does not exist after copying!" >&2
        test_status=1
    fi
fi

# Verify WORKSPACE contains the workspace name
if [ $test_status -eq 0 ]; then
    if ! grep -q 'workspace(name = "com_github_google_benchmark")' "WORKSPACE"; then
        echo "ERROR: WORKSPACE does not contain expected workspace name!" >&2
        test_status=1
    fi
fi

# Verify test/BUILD contains expected Bazel content
if [ $test_status -eq 0 ]; then
    if ! grep -q 'load("//bazel:have_regex.bzl"' "test/BUILD"; then
        echo "ERROR: test/BUILD does not contain expected Bazel load statement!" >&2
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
