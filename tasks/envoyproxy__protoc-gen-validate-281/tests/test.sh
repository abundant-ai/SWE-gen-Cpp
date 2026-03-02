#!/bin/bash

cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

export CI=true

# Rebuild protoc-gen-validate to ensure templates compile
# The bug.patch removes recursive map validation support
# The fix.patch adds recursive map validation support for C++, Go, and Python
GO111MODULE=off make build 2>&1 | tail -50
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that the templates support recursive map validation
# The key indicator is the presence of recursive validation logic in the map template

# For C++: Check if templates/cc/map.go includes logic to validate map element messages
# With bug: recursive validation is removed from cType() for maps
# With fix: cType() includes logic for map element types, enabling recursive validation
if grep -q 'else if t.IsMap()' templates/cc/register.go; then
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
