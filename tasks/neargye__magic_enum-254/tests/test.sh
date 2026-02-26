#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/.bazelrc" "test/.bazelrc"
mkdir -p "test"
cp "/tests/BUILD.bazel" "test/BUILD.bazel"
mkdir -p "test"
cp "/tests/MODULE.bazel" "test/MODULE.bazel"
mkdir -p "test"
cp "/tests/WORKSPACE.bazel" "test/WORKSPACE.bazel"

# Update root BUILD.bazel to remove old test/example targets that conflict with new subpackages
# The BASE state has old-style targets; we need the simplified HEAD version
cat > BUILD.bazel << 'EOF'
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//bazel:copts.bzl", "COPTS")

licenses(["notice"])

exports_files(["LICENSE"])

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "magic_enum",
    hdrs = glob(["include/*.hpp"]),
    copts = COPTS,
    includes = ["include"],
)
EOF

# Copy other necessary Bazel files from HEAD state
mkdir -p bazel bazel/platforms
cat > bazel/BUILD.bazel << 'EOF'
EOF

cat > bazel/copts.bzl << 'EOF'
COPTS = select({
    "@bazel_tools//tools/cpp:msvc": ["/std:c++17", "/permissive-"],
    "//conditions:default": ["-std=c++17"],
})
EOF

cat > bazel/platforms/BUILD.bazel << 'EOF'
package(default_visibility = ["//:__subpackages__"])

platform(
    name = "linux",
    constraint_values = [
        "@platforms//os:linux",
        "@bazel_tools//tools/cpp:clang",
    ],
)

platform(
    name = "macos",
    constraint_values = [
        "@platforms//os:osx",
        "@bazel_tools//tools/cpp:clang",
    ],
)

platform(
    name = "windows",
    constraint_values = [
        "@platforms//os:windows",
        "@bazel_tools//tools/cpp:msvc",
    ],
)
EOF

# Rebuild and run tests with the updated Bazel configuration
cd test
bazel test //... --test_output=errors --jobs=1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
