#!/bin/bash

cd /app/src

# Environment variables for Bazel tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/core/src/test/java/com/google/protobuf"
cp "/tests/java/core/src/test/java/com/google/protobuf/IsValidUtf8TestUtil.java" "java/core/src/test/java/com/google/protobuf/IsValidUtf8TestUtil.java"
mkdir -p "java/lite/src/test/java/com/google/protobuf"
cp "/tests/java/lite/src/test/java/com/google/protobuf/LiteTest.java" "java/lite/src/test/java/com/google/protobuf/LiteTest.java"
mkdir -p "java/util/src/test/java/com/google/protobuf/util"
cp "/tests/java/util/src/test/java/com/google/protobuf/util/JsonFormatTest.java" "java/util/src/test/java/com/google/protobuf/util/JsonFormatTest.java"

# Run the specific Java tests using Bazel
bazel test //java/core:utf8_tests //java/lite:lite_tests //java/util:tests --test_output=errors
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
