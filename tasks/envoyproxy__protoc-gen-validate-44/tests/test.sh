#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests if fix.patch has been applied (Oracle agent only)
# The fix.patch restores pgv::ValidationMsg typedef and pgv::UnimplementedException class
# Check if the fix has been applied by looking for ValidationMsg typedef in validate.h
if grep -q 'using ValidationMsg = std::string' validate/validate.h 2>/dev/null; then
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify that the C++ validation headers define the required types for the harness
# In buggy state (BASE with bug.patch):
#   - validate.h is missing pgv::ValidationMsg typedef
#   - validate.h is missing pgv::UnimplementedException class
#   - harness.cc uses these types but they don't exist (compilation will fail)
# In fixed state (HEAD with fix.patch):
#   - validate.h defines pgv::ValidationMsg as an alias for std::string
#   - validate.h defines pgv::UnimplementedException class
#   - harness.cc compiles successfully using these types

echo "Checking if C++ validation headers define required types..." >&2

if [ ! -f validate/validate.h ]; then
  echo "ERROR: validate/validate.h not found!" >&2
  test_status=1
else
  # Check if validate.h has the required types
  # In the BUGGY version: ValidationMsg typedef is missing
  # In the FIXED version: ValidationMsg typedef exists

  if grep -q 'using ValidationMsg = std::string' validate/validate.h; then
    echo "FIXED: Found ValidationMsg typedef in validate.h" >&2

    # Also check for UnimplementedException class
    if grep -q 'class UnimplementedException' validate/validate.h; then
      echo "FIXED: Found UnimplementedException class in validate.h" >&2
      test_status=0
    else
      echo "ERROR: ValidationMsg found but UnimplementedException missing" >&2
      test_status=1
    fi
  else
    echo "BUGGY: ValidationMsg typedef not found in validate.h" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
