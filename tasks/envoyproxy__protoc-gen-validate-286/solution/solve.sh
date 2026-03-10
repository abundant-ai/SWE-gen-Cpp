#!/bin/bash

set -euo pipefail
cd /go/src/github.com/envoyproxy/protoc-gen-validate

patch -p1 < /solution/fix.patch
