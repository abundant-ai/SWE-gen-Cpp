#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/envoyproxy/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild Java project after applying fix (dependency changes require rebuild)
cd java && mvn clean install -DskipTests
