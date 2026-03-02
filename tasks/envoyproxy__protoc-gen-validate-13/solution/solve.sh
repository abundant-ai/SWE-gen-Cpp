#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/lyft/protoc-gen-validate

patch -p1 < /solution/fix.patch

# Rebuild protoc-gen-validate binary to pick up template changes
GO111MODULE=off make build
