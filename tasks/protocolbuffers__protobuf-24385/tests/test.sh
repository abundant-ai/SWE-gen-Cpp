#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "src/google/protobuf/compiler/kotlin"
cp "/tests/src/google/protobuf/compiler/kotlin/annotation_test.cc" "src/google/protobuf/compiler/kotlin/annotation_test.cc"

# The fix changes the Kotlin generator to embed annotations as inline base64 comments
# instead of separate .pb.meta files.
# BASE state (bug): Writes to .pb.meta files, missing absl/strings/escaping.h include
# HEAD state (fix): Writes inline base64 comments, has absl/strings/escaping.h include

test_status=1

# Check that the generator code has the inline comment format (HEAD state)
# It should have absl/strings/escaping.h include and Base64Escape usage
if grep -q '#include "absl/strings/escaping.h"' "src/google/protobuf/compiler/kotlin/file.cc" &&  \
   grep -q "absl::Base64Escape" "src/google/protobuf/compiler/kotlin/file.cc"; then
  echo "✓ Code uses inline base64 annotation format (HEAD/fix state)"
  test_status=0
else
  echo "✗ Code uses .pb.meta file format (BASE/bug state)"
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
