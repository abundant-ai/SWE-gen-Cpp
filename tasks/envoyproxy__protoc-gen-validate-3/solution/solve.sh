#!/bin/bash

set -euo pipefail
cd /root/go/src/github.com/lyft/protoc-gen-validate

patch -p1 < /solution/fix.patch
