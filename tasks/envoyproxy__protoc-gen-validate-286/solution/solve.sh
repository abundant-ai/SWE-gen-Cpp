#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

# Apply the fix patch
patch -p1 < /solution/fix.patch

# Rebuild the protoc-gen-validate plugin with the fix
GO111MODULE=off make build

# Rebuild Java project with the fixed code generation
cd java && mvn clean install -DskipTests
