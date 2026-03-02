#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild Go plugin after applying fix
GO111MODULE=off make build

# Rebuild Java project after applying fix
cd java && mvn clean install -DskipTests
