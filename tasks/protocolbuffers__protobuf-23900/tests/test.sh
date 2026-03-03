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

# CRITICAL: Run ONLY the specific test files from the PR, NOT the entire test suite!
# The test files to run are: "java/core/src/test/java/com/google/protobuf/GeneratorNamesTest.java" "java/core/src/test/proto/com/google/protobuf/generator_names_UnusualFile0name.protodevel" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_enum.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_message.proto" "java/core/src/test/proto/com/google/protobuf/generator_names_conflicting_nested_enum.proto" # ... and 9 more
#
# TODO: Fill in the actual test command to run ONLY these specific files
#
# DO NOT run the entire test suite - it's too slow and may have unrelated failures!
#
# Examples for different languages/frameworks:
#
# Python (pytest with uv):
#   # If using uv venv at /opt/venv:
#   source /opt/venv/bin/activate
#   uv pip install -e . --no-deps 2>/dev/null || true  # Reinstall to pick up changes
#   pytest -xvs path/to/test_file.py
#   # Or without venv activation:
#   /opt/venv/bin/pytest -xvs path/to/test_file.py
#
# JavaScript/TypeScript (IMPORTANT: disable coverage thresholds when running subset!):
#   npx jest path/to/test.js path/to/test2.js --coverage=false
#   npx vitest run path/to/test.ts --coverage.enabled=false
#   npx mocha path/to/test.js path/to/test2.js
#   npx borp path/to/test.js --no-check-coverage   # Used by fastify, pino, etc.
#   npx tap path/to/test.js --no-check-coverage    # Node TAP framework
#   npx ava path/to/test.js                        # AVA framework
#
#   CRITICAL for JS/TS: DO NOT use "npm test" or "npm run test" without args!
#   These run the ENTIRE suite. Pass specific files via the test runner directly.
#   If you must use npm: npm run test -- path/to/test.js (note the -- separator)
#
# Go:
#   go test -v ./path/to/package/...
#   go test -v -run TestSpecificName ./...
#
# Rust:
#   cargo test --test test_name -- --nocapture
#   cargo test specific_test_name -- --nocapture
#
# Ruby (RSpec/Minitest):
#   bundle exec rspec path/to/spec.rb
#   bundle exec ruby -Itest path/to/test.rb
#
# Java (JUnit/Maven/Gradle):
#   mvn test -Dtest=TestClassName
#   gradle test --tests TestClassName

# Run Bazel test for GeneratorNamesTest specifically
bazel test //java/core:core_tests --test_filter=GeneratorNamesTest
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
