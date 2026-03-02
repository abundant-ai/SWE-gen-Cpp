#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/lyft/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild the protoc-gen-validate plugin for the template changes to take effect
export GO111MODULE=off
make build
