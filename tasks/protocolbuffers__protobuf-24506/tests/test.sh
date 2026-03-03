#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf/compiler/kotlin"
cp "/tests/src/google/protobuf/compiler/kotlin/annotation_test.cc" "src/google/protobuf/compiler/kotlin/annotation_test.cc"

# Add BUILD target for annotation_test
cat >> src/google/protobuf/compiler/kotlin/BUILD.bazel <<'EOF'

cc_test(
    name = "annotation_test",
    srcs = ["annotation_test.cc"],
    deps = [
        ":kotlin",
        "//:protobuf",
        "//src/google/protobuf",
        "//src/google/protobuf/compiler:annotation_test_util",
        "//src/google/protobuf/compiler:command_line_interface",
        "//src/google/protobuf/testing",
        "//src/google/protobuf/testing:file",
        "@abseil-cpp//absl/log:absl_check",
        "@abseil-cpp//absl/strings",
        "@googletest//:gtest",
        "@googletest//:gtest_main",
    ],
)
EOF

# Run the annotation_test (has changes that will fail in BASE state)
bazel test //src/google/protobuf/compiler/kotlin:annotation_test --test_output=errors --nocache_test_results
test_status=$?

# Shutdown Bazel server to avoid hanging
bazel shutdown

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
