#!/bin/bash

cd /app/src

# For this PR, the bug is about missing ARM64/PPC64 defines in the header files
# We test by creating a simple program that checks if the defines are present

# Create a test that checks for the required defines
cat > tests/check_defines.cpp << 'EOF'
#include "simdjson.h"
#include <stdio.h>

int main() {
  // Check if ARM64 defines are present
  #ifdef SIMDJSON_CAN_ALWAYS_RUN_ARM64
    printf("ARM64 define found\n");
  #else
    printf("ERROR: ARM64 define missing\n");
    return 1;
  #endif

  // Check if PPC64 defines are present
  #ifdef SIMDJSON_CAN_ALWAYS_RUN_PPC64
    printf("PPC64 define found\n");
  #else
    printf("ERROR: PPC64 define missing\n");
    return 1;
  #endif

  printf("All required defines present\n");
  return 0;
}
EOF

# Reconfigure CMake and build the library
cmake -DCMAKE_BUILD_TYPE=Debug -DSIMDJSON_DEVELOPER_MODE=ON -DSIMDJSON_CXX_STANDARD=20 -DSIMDJSON_MINUS_ZERO_AS_FLOAT=ON -B build
cmake --build build --target simdjson -j=2

# Build and run the test
test_status=0
if ! g++ -std=c++20 -I include tests/check_defines.cpp -Lbuild -lsimdjson -Wl,-rpath,/app/src/build -o /tmp/check_defines 2>&1; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  set +e
  LD_LIBRARY_PATH=/app/src/build:$LD_LIBRARY_PATH /tmp/check_defines
  test_exit=$?
  set -e
  if [ $test_exit -ne 0 ]; then
    test_status=1
  fi
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
