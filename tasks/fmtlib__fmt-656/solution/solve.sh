#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 < /solution/fix.patch

# Add missing cstdint include required for GCC 13+ (Ubuntu 24.04)
sed -i '/#include <cstring>/a #include <cstdint>' include/fmt/core.h
