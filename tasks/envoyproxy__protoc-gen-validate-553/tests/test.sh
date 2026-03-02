#!/bin/bash
set -x
cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/harness/cases"
cp "/tests/harness/cases/repeated.proto" "tests/harness/cases/repeated.proto"

# Rebuild the plugin to pick up any template changes
make build

# Regenerate test cases from proto files
make testcases

# Check if the generated code contains the lookup variable definitions
# The fix adds InLookup and NotInLookup map variables for repeated.items.any.in/not_in
if grep -q "^var _RepeatedAnyIn_Val_InLookup = map\[string\]struct" tests/harness/cases/go/repeated.pb.validate.go 2>/dev/null; then
    in_lookup_found=1
else
    in_lookup_found=0
fi

if grep -q "^var _RepeatedAnyNotIn_Val_NotInLookup = map\[string\]struct" tests/harness/cases/go/repeated.pb.validate.go 2>/dev/null; then
    not_in_lookup_found=1
else
    not_in_lookup_found=0
fi

# Test passes if both lookup definitions are found
if [ $in_lookup_found -eq 1 ] && [ $not_in_lookup_found -eq 1 ]; then
    echo 1 > /logs/verifier/reward.txt
    exit 0
else
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
