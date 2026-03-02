#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files if fix has been applied (detected by C++ syntax in templates)
if grep -q 'const std::string prefix' templates/cc/bytes.go 2>/dev/null; then
mkdir -p "tests/harness/cc"
cp "/tests/harness/cc/harness.cc" "tests/harness/cc/harness.cc"
fi

# Verify C++ bytes validation code generation is correct
# Buggy: uses Go syntax (bytes.HasPrefix, etc.)
# Fixed: uses C++ syntax (const std::string prefix, .compare(), etc.)
echo "Checking if C++ bytes validation code generation is correct..." >&2

if [ ! -f templates/cc/bytes.go ]; then
  echo "ERROR: templates/cc/bytes.go not found!" >&2
  test_status=1
else
  if grep -q 'const std::string prefix' templates/cc/bytes.go && \
     grep -q '{{ template "const" \. }}' templates/cc/bytes.go; then
    echo "FIXED: Found C++ syntax in templates/cc/bytes.go" >&2
    test_status=0
  else
    echo "BUGGY: C++ syntax not found in templates/cc/bytes.go (uses Go syntax instead)" >&2
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
