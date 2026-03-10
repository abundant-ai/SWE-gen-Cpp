#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "java/pgv-java-grpc/src/test/proto"
cp "/tests/java/pgv-java-grpc/src/test/proto/BUILD.bazel" "java/pgv-java-grpc/src/test/proto/BUILD.bazel"

# This test verifies that multiple BUILD.bazel files have been updated to use the new Bazel
# naming convention with deprecation aliases instead of the old go_default_library pattern.
#
# In the buggy state (BASE with bug.patch applied):
#   - BUILD files use go_default_library as the main target name
#   - No deprecation aliases for the new naming convention
#
# In the fixed state (BASE + HEAD test files + fix.patch):
#   - BUILD files use semantic names (module, templates, proto, etc.)
#   - Have deprecation aliases pointing go_default_library -> new name
#
# The test verifies OTHER files not in /tests/ to check if fix.patch was applied

echo "Testing if BUILD files have the new naming convention..." >&2

# Check module/BUILD - should have "module" as main name with alias in FIXED state
if grep -q 'name = "module"' module/BUILD 2>/dev/null && \
   grep -q 'actual = ":module"' module/BUILD 2>/dev/null; then
    echo "FIXED: module/BUILD has new naming" >&2
    has_module=1
else
    echo "BUGGY: module/BUILD uses old naming" >&2
    has_module=0
fi

# Check templates/BUILD.bazel - should have "templates" as main name with alias in FIXED state
if grep -q 'name = "templates"' templates/BUILD.bazel 2>/dev/null && \
   grep -q 'actual = ":templates"' templates/BUILD.bazel 2>/dev/null; then
    echo "FIXED: templates/BUILD.bazel has new naming" >&2
    has_templates=1
else
    echo "BUGGY: templates/BUILD.bazel uses old naming" >&2
    has_templates=0
fi

# Check validate/BUILD - should have "validate_go" with alias in FIXED state
if grep -q 'name = "validate_go"' validate/BUILD 2>/dev/null && \
   grep -q 'actual = ":validate_go"' validate/BUILD 2>/dev/null; then
    echo "FIXED: validate/BUILD has new naming" >&2
    has_validate=1
else
    echo "BUGGY: validate/BUILD uses old naming" >&2
    has_validate=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_module -eq 1 ] && [ $has_templates -eq 1 ] && [ $has_validate -eq 1 ]; then
    echo "PASS: All fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
