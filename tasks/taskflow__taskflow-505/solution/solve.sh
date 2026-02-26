#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 < /solution/fix.patch

# Rebuild libraries after applying fix (but don't try to build test_chunk_context yet)
# The test file will be copied by test.sh before the test is built
cmake --build build --parallel $(nproc) || true
