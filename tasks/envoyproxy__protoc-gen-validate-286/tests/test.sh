#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Rebuild protoc-gen-validate to ensure templates compile
# The bug.patch modifies C++ templates to mark pattern validation as unimplemented
# The fix.patch adds RE2-based pattern validation
GO111MODULE=off make build 2>&1 | tail -50
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that the C++ template includes RE2 header (sign that pattern validation is implemented)
# With bug: pattern validation is marked unimplemented, no RE2 include
# With fix: RE2 header is included for pattern matching
if grep -q '#include "re2/re2.h"' templates/cc/file.go; then
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
