#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild after applying the fix
GO111MODULE=off make build

# Rebuild Java project after applying the fix
cd java && mvn clean install -DskipTests
