#!/bin/bash
cd /app/src

export CI=true

# Rebuild the plugin to pick up any changes from solve.sh (if Oracle ran it)
make build

# The fix updates the BUILD.bazel file to use the new naming convention
# With the bug (BASE state): Uses direct name "go_default_library" with no alias
# With the fix (HEAD state): Uses new name "proto" with an alias pointing to it for backwards compat

# Check if the BUILD.bazel file has the correct structure with the fix applied
# With the fix, it should have:
# - go_library name = "proto" (not "go_default_library")
# - A separate alias block (for backwards compatibility)

# Check that go_library name is "proto" (not "go_default_library")
if grep -A 3 'go_library(' java/pgv-java-grpc/src/test/proto/BUILD.bazel | grep -q 'name = "proto"'; then
    fix_applied=1
else
    fix_applied=0
fi

# Also check that there IS an alias block (the fixed version has an alias for backwards compat)
if grep -q '^alias(' java/pgv-java-grpc/src/test/proto/BUILD.bazel; then
    # alias found means fix is applied
    :
else
    # no alias means bug is still present
    fix_applied=0
fi

# Test passes if fix is applied (proto name and has alias)
if [ $fix_applied -eq 1 ]; then
    test_status=0
else
    echo "Test failed - BUILD.bazel file doesn't have the correct structure with the fix"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
