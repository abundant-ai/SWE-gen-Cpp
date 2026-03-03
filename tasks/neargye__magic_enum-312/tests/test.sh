#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/BUILD.bazel" "test/BUILD.bazel"
mkdir -p "test"
cp "/tests/MODULE.bazel" "test/MODULE.bazel"

# Remove incompatible flag from .bazelrc to avoid issues with older Bazel versions
sed -i '/--incompatible_use_platforms_repo_for_constraints/d' /app/src/.bazelrc

# The fix removes dependency on rules_cc and bazel/copts.bzl from magic_enum
# Test by removing rules_cc from MODULE and verifying build still works
# In buggy state: BUILD tries to load //bazel:copts.bzl which needs rules_cc -> fails
# In fixed state: BUILD doesn't use bazel/copts.bzl -> succeeds
sed -i '/bazel_dep(name = "rules_cc"/d' MODULE.bazel
sed -i '/bazel_dep(name = "bazel_skylib"/d' MODULE.bazel
bazel build //:magic_enum 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
