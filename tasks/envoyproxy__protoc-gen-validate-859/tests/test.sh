#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
# NOTE: Only copy test files, NOT source files containing the fix!
# This allows NOP to fail (source files remain buggy) and Oracle to pass (with fix applied)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/BUILD" "tests/harness/cases/BUILD"
cp "/tests/harness/cases/enums.proto" "tests/harness/cases/enums.proto"
mkdir -p "tests/harness/cases/sort"
cp "/tests/harness/cases/sort/BUILD" "tests/harness/cases/sort/BUILD"
cp "/tests/harness/cases/sort/sort.proto" "tests/harness/cases/sort/sort.proto"
mkdir -p "tests/harness/executor"
cp "/tests/harness/executor/BUILD" "tests/harness/executor/BUILD"
cp "/tests/harness/executor/cases.go" "tests/harness/executor/cases.go"
mkdir -p "tests/harness/go/main"
cp "/tests/harness/go/main/BUILD" "tests/harness/go/main/BUILD"

# The test verifies that the collision detection logic in templates/goshared/register.go
# correctly handles the case where a proto package name collides with a standard library import.
#
# In the buggy state (BASE with bug.patch applied):
#   - The sort package is removed from various BUILD files and test files
#   - The collision detection logic is simplified and doesn't properly handle collisions
#
# In the fixed state (BASE + HEAD test files):
#   - The sort package is re-added to BUILD files and test files
#   - The collision detection logic properly detects and avoids name collisions
#   - Generated Go code should use "sort1" or similar alias for the proto package
#     while keeping "sort" for the standard library

echo "Testing if collision detection works correctly for 'sort' package..." >&2

# Check if the sort package exists in the test files
if [ -d "tests/harness/cases/sort" ] && [ -f "tests/harness/cases/sort/sort.proto" ]; then
    echo "FIXED: sort package exists in test files" >&2
    has_sort_package=1
else
    echo "BUGGY: sort package is missing from test files" >&2
    has_sort_package=0
fi

# Check if enums.proto imports the sort package
if grep -q 'import "tests/harness/cases/sort/sort.proto"' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto imports sort package" >&2
    has_sort_import=1
else
    echo "BUGGY: enums.proto does not import sort package" >&2
    has_sort_import=0
fi

# Check if enums.proto uses the sort.Direction enum
if grep -q 'sort.Direction' tests/harness/cases/enums.proto 2>/dev/null; then
    echo "FIXED: enums.proto uses sort.Direction enum" >&2
    has_sort_usage=1
else
    echo "BUGGY: enums.proto does not use sort.Direction enum" >&2
    has_sort_usage=0
fi

# Check if BUILD files reference the sort package
if grep -q '//tests/harness/cases/sort' tests/harness/cases/BUILD 2>/dev/null; then
    echo "FIXED: BUILD files reference sort package" >&2
    has_sort_build_refs=1
else
    echo "BUGGY: BUILD files do not reference sort package" >&2
    has_sort_build_refs=0
fi

# Check if executor/cases.go imports and uses the sort package
if grep -q 'github.com/envoyproxy/protoc-gen-validate/tests/harness/cases/sort' tests/harness/executor/cases.go 2>/dev/null && \
   grep -q 'sort.Direction' tests/harness/executor/cases.go 2>/dev/null; then
    echo "FIXED: executor/cases.go imports and uses sort package" >&2
    has_executor_sort=1
else
    echo "BUGGY: executor/cases.go does not properly use sort package" >&2
    has_executor_sort=0
fi

# Check if the collision detection logic in templates/goshared/register.go has been improved
# The buggy version has: nameCollision := make(map[pgs.Name]int)
# The fixed version has: nameCollision := map[pgs.Name]int{"bytes": 0, "errors": 0, "fmt": 0, ...}
if grep -q 'nameCollision := map\[pgs.Name\]int{' templates/goshared/register.go 2>/dev/null && \
   grep -q '"sort".*:.*0' templates/goshared/register.go 2>/dev/null; then
    echo "FIXED: register.go has proper collision detection with pre-populated map" >&2
    has_collision_fix=1
else
    echo "BUGGY: register.go has empty collision detection map" >&2
    has_collision_fix=0
fi

# Check if .gitignore includes sort package paths
if grep -q '/tests/harness/cases/sort/go' .gitignore 2>/dev/null && \
   grep -q '/tests/harness/cases/sort/gogo' .gitignore 2>/dev/null; then
    echo "FIXED: .gitignore includes sort package paths" >&2
    has_gitignore_fix=1
else
    echo "BUGGY: .gitignore missing sort package paths" >&2
    has_gitignore_fix=0
fi

# Check if Makefile includes sort package build steps
if grep -q 'rm -r tests/harness/cases/sort/go' Makefile 2>/dev/null && \
   grep -q 'mkdir tests/harness/cases/sort/go' Makefile 2>/dev/null; then
    echo "FIXED: Makefile includes sort package build steps" >&2
    has_makefile_fix=1
else
    echo "BUGGY: Makefile missing sort package build steps" >&2
    has_makefile_fix=0
fi

# Test passes if all checks pass (meaning fix is present)
if [ $has_sort_package -eq 1 ] && [ $has_sort_import -eq 1 ] && [ $has_sort_usage -eq 1 ] && \
   [ $has_sort_build_refs -eq 1 ] && [ $has_executor_sort -eq 1 ] && [ $has_collision_fix -eq 1 ] && \
   [ $has_gitignore_fix -eq 1 ] && [ $has_makefile_fix -eq 1 ]; then
    echo "PASS: All collision detection fixes are present" >&2
    test_status=0
else
    echo "FAIL: Some collision detection fixes are missing" >&2
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
