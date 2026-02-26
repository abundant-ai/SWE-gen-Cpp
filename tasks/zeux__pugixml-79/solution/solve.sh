#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 -l < /solution/fix.patch
