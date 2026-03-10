#!/bin/bash
set -e

# Trap errors and write reward=0
trap 'echo 0 > /logs/verifier/reward.txt' ERR

cd /app/src

# Rebuild in the existing build directory (faster than rebuilding from scratch)
cd build

# Remove test executable to force rebuild
rm -f googletest/gtest_unittest

# Reconfigure with -Wsuggest-override and turn suggest-override warnings into errors
# Note: GoogleTest's CMake sets -Werror by default, so we need to explicitly disable unused-but-set-variable errors
cmake -DCMAKE_CXX_FLAGS="-std=c++11 -Wsuggest-override -Werror=suggest-override -Wno-error=unused-but-set-variable" .. 2>&1

# Build only the specific test target
# For NOP (BASE): This should FAIL because override keywords are missing
# For Oracle (HEAD): This should SUCCEED because override keywords are present
make -j4 gtest_unittest 2>&1

# If compilation succeeded, run the test to ensure it works
./googletest/gtest_unittest 2>&1

# If we got here, compilation and tests passed
trap - ERR  # Clear the trap
echo 1 > /logs/verifier/reward.txt
exit 0
