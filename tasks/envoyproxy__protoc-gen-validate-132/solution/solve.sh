#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/lyft/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild Java project after applying fix.patch so tests can compile against updated classes
cd java && mvn clean install -DskipTests
