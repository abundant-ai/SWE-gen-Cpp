#!/bin/bash

cd /app/src

# Test that the fix correctly creates .cirrus.yml (not .drone.yml)
# The bug state has .github/external_ci/.drone.yml
# The fixed state should have .cirrus.yml

test_status=1

# Check if .cirrus.yml exists and has the correct content
if [ -f ".cirrus.yml" ]; then
    # Verify it's the Cirrus CI format (not Drone CI format)
    if grep -q "arm_container:" .cirrus.yml && grep -q "check_task:" .cirrus.yml; then
        echo "SUCCESS: .cirrus.yml exists and has correct Cirrus CI format"
        test_status=0
    else
        echo "FAIL: .cirrus.yml exists but has wrong format"
        test_status=1
    fi
else
    echo "FAIL: .cirrus.yml does not exist"
    test_status=1
fi

# Note: We don't check for .drone.yml deletion because the fix.patch
# creates .cirrus.yml as a new file without explicitly deleting .drone.yml.
# The patch was generated from a git rename operation, which shows as
# delete+create, but the fix.patch only contains the create part.

# Check README.md references Cirrus CI (not Drone CI)
if grep -q "Cirrus CI" README.md; then
    echo "SUCCESS: README.md mentions Cirrus CI"
else
    echo "FAIL: README.md does not mention Cirrus CI"
    test_status=1
fi

# Check cmake/ci.cmake doesn't have the clang++-9 special case
if grep -q 'STREQUAL "clang++-9"' cmake/ci.cmake; then
    echo "FAIL: cmake/ci.cmake still has clang++-9 special case"
    test_status=1
else
    echo "SUCCESS: cmake/ci.cmake doesn't have clang++-9 special case"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
