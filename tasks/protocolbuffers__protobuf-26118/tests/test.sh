#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf/compiler/rust"
cp "/tests/src/google/protobuf/compiler/rust/generator_test.cc" "src/google/protobuf/compiler/rust/generator_test.cc"

# Add the test target to the BUILD file (since bug.patch removed the test file, the BUILD target may not exist)
cat >> src/google/protobuf/compiler/rust/BUILD << 'EOF'

cc_test(
    name = "generator_test",
    srcs = ["generator_test.cc"],
    deps = [
        ":context",
        ":rust",
        "//src/google/protobuf",
        "//src/google/protobuf/compiler:code_generator",
        "//src/google/protobuf/compiler:command_line_interface",
        "//src/google/protobuf/compiler:command_line_interface_tester",
        "@abseil-cpp//absl/strings",
        "@googletest//:gtest",
        "@googletest//:gtest_main",
    ],
)
EOF

# Run the specific test using Bazel
bazel test //src/google/protobuf/compiler/rust:generator_test --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
