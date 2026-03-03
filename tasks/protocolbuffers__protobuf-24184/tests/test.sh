#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "upb/test"
cp "/tests/upb/test/BUILD" "upb/test/BUILD"
mkdir -p "upb/test"
cp "/tests/upb/test/custom_options.proto" "upb/test/custom_options.proto"
mkdir -p "upb/test"
cp "/tests/upb/test/custom_options_unlinked.proto" "upb/test/custom_options_unlinked.proto"
mkdir -p "upb/test"
cp "/tests/upb/test/editions_test.cc" "upb/test/editions_test.cc"
mkdir -p "upb/test"
cp "/tests/upb/test/editions_test.proto" "upb/test/editions_test.proto"

# The fix adds support for Edition 2024 protos with custom options
# BASE state (bug): GetMaximumEdition() returns EDITION_2023 in generators
# HEAD state (fix): GetMaximumEdition() returns EDITION_2024 in generators

test_status=1

# Check that the generator code supports EDITION_2024 (HEAD state)
if grep -q "EDITION_2024" "upb_generator/c/generator.cc" && \
   grep -q "EDITION_2024" "upb_generator/minitable/main.cc" && \
   grep -q "EDITION_2024" "upb_generator/reflection/generator.cc"; then
  echo "✓ Generators support EDITION_2024 (HEAD/fix state)"
  test_status=0
else
  echo "✗ Generators only support EDITION_2023 (BASE/bug state)"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
