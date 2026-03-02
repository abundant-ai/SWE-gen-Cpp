#!/bin/bash

cd /app/src

# The fix adds stack size linker flags for MSVC to prevent stack overflow in test/CMakeLists.txt
# Verify that test/CMakeLists.txt contains the required linker flags
# The Oracle agent should have applied fix.patch which adds these lines
if grep -q 'set_property.*test-cbor.*LINK_FLAGS.*STACK:4000000' test/CMakeLists.txt && \
   grep -q 'set_property.*test-msgpack.*LINK_FLAGS.*STACK:4000000' test/CMakeLists.txt && \
   grep -q 'set_property.*test-ubjson.*LINK_FLAGS.*STACK:4000000' test/CMakeLists.txt; then
    echo 1 > /logs/verifier/reward.txt
    exit 0
else
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi
