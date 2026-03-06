#!/bin/bash

cd /app/src

# Environment variables for tests
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/core/src/test/java/com/google/protobuf"
cp "/tests/java/core/src/test/java/com/google/protobuf/GeneratorNamesTest.java" "java/core/src/test/java/com/google/protobuf/GeneratorNamesTest.java"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_UnusualFile0name.protodevel" "java/core/src/test/proto/com/google/protobuf/generator_names_UnusualFile0name.protodevel"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_enum.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_enum.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_message.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_message.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_nested_enum.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_nested_enum.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_nested_message.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_nested_message.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_service.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_service.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_edition2024_defaults.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_edition2024_defaults.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_generic_services.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_generic_services.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_multiple_files_proto2.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_multiple_files_proto2.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_multiple_files_proto3.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_multiple_files_proto3.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_nest_in_file_class.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_nest_in_file_class.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_outer_classname.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_outer_classname.proto"
mkdir -p "java/core/src/test/proto/com/google/protobuf"
cp "/tests/java/core/src/test/proto/com/google/protobuf/generator_names_pre2024_defaults.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_pre2024_defaults.proto"

# Run Bazel test for GeneratorNamesTest specifically
# Note: We filter to run only GeneratorNamesTest, but check its specific pass/fail status
# because copying proto files affects other tests in the suite
bazel test //java/core:core_tests --test_filter=GeneratorNamesTest --test_output=errors --keep_going 2>&1 | tee /tmp/test_output.txt

# Check if GeneratorNamesTest specifically passed
if grep -q "//java/core:GeneratorNamesTest.*PASSED" /tmp/test_output.txt; then
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
