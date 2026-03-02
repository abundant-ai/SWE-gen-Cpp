#!/bin/bash

cd /root/go/src/github.com/lyft/protoc-gen-validate

export CI=true
export GO111MODULE=off

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/kitchensink"
cp "/tests/kitchensink/oneof.proto" "tests/kitchensink/oneof.proto"

# Generate Go code ONLY for oneof.proto using protoc-gen-validate
echo "Regenerating Go validation code for oneof.proto..." >&2
rm -rf tests/kitchensink/go || true
mkdir -p tests/kitchensink/go
cd tests/kitchensink && \
protoc \
	-I . \
	-I ../.. \
	--go_out="Mvalidate/validate.proto=github.com/lyft/protoc-gen-validate/validate:./go" \
	--validate_out="lang=go:./go" \
	oneof.proto

cd /root/go/src/github.com/lyft/protoc-gen-validate

# The test verifies that the generated validation code doesn't have type collision errors
# In the buggy state:
#   - Name collision detection is missing (only checks f.Type().Name())
#   - With the complex oneof.proto (fields: embed, other_embed), wrapper names collide with nested types
#   - Generated oneof.pb.validate.go will have type switch cases that reference non-existent wrapper types
#   - Compilation will fail with "impossible type switch case" errors for OneOf_Embed and OneOf_OtherEmbed
# In the fixed state:
#   - Name collision detection properly loops through all nested enums and messages
#   - Colliding names get "_" appended (e.g., OneOf_Embed becomes OneOf_Embed_)
#   - Generated code has no type collision errors
echo "Testing if generated validation code has no type collision errors..." >&2
cd tests/kitchensink/go
build_output=$(go build oneof.pb.go oneof.pb.validate.go 2>&1)
build_exit=$?

# Check if the build output contains the specific "impossible type switch case" errors
# that indicate name collisions in the oneof wrapper types
if echo "$build_output" | grep -q "impossible type switch case.*OneOf_"; then
    echo "BUGGY: Generated code has type collisions in oneof wrappers" >&2
    test_status=1
else
    echo "FIXED: No type collision errors in generated validation code" >&2
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
