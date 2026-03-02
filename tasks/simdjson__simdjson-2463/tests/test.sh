#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/builder"
cp "/tests/builder/CMakeLists.txt" "tests/builder/CMakeLists.txt"
mkdir -p "tests/builder"
cp "/tests/builder/static_reflection_custom_tests.cpp" "tests/builder/static_reflection_custom_tests.cpp"

# This PR completes the documentation for tag_invoke customization
# The test verifies that the documentation exists in builder.md and concepts.h
# In BASE state (after bug.patch), the documentation is removed
# Oracle agent needs to add it back for tests to pass

test_status=1

# Check if tag_invoke documentation exists in builder.md (first section)
if grep -q "You can also add custom serialization functions using a .tag_invoke. function" doc/builder.md 2>/dev/null; then
    echo "First tag_invoke documentation section found in doc/builder.md"
    test_status=0
else
    echo "First tag_invoke documentation section not found in doc/builder.md - documentation is missing"
    test_status=1
fi

# Check if tag_invoke customization section exists in builder.md
if grep -q "### Customization" doc/builder.md 2>/dev/null; then
    echo "Customization section found in doc/builder.md"
    test_status=0
else
    echo "Customization section not found in doc/builder.md - documentation is missing"
    test_status=1
fi

# Check if tag_invoke comment exists in concepts.h
if grep -q "We use tag_invoke as our customization point mechanism" include/simdjson/concepts.h 2>/dev/null; then
    echo "tag_invoke comment found in concepts.h"
    test_status=0
else
    echo "tag_invoke comment not found in concepts.h - documentation is missing"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
