#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/SelfTest/IntrospectiveTests"
cp "/tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp" "tests/SelfTest/IntrospectiveTests/TextFlow.tests.cpp"

# Rebuild after copying the updated test file
# If build fails, the test should fail
if ! cmake --build build; then
    echo "Build failed - test cannot run"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Run only the TextFlow tests using Catch2's tag filter
# The test file has various tags like [TextFlow], [column], [ansiskippingstring], [approvals]
./build/tests/SelfTest "[TextFlow]"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
