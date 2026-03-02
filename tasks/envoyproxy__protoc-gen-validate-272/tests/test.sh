#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Rebuild protoc-gen-validate to ensure templates compile
# The bug.patch removes support for filenames with dashes (like filename-with-dash.proto)
# The fix.patch adds support by using screaming_snake_case instead of upper for C++ macros
GO111MODULE=off make build 2>&1 | tail -50
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that the templates use screaming_snake_case for filename handling
# With bug: uses "upper" function which doesn't handle dashes properly (e.g., filename-with-dash -> FILENAME-WITH-DASH)
# With fix: uses "screaming_snake_case" function which converts dashes to underscores (e.g., filename-with-dash -> FILENAME_WITH_DASH)
# We check both that screaming_snake_case is used in the template functions AND that the strcase import is present
if grep -q '"screaming_snake_case":' templates/cc/register.go && grep -q 'github.com/iancoleman/strcase' templates/cc/register.go; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
