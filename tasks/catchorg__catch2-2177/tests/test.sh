#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/CMakeLists.txt" "tests/CMakeLists.txt"

# Reconfigure CMake with CATCH_BUILD_SURROGATES enabled
if ! cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCATCH_DEVELOPMENT_BUILD=ON \
    -DCATCH_BUILD_TESTING=ON \
    -DCATCH_BUILD_SURROGATES=ON \
    -DCATCH_BUILD_EXTRA_TESTS=OFF \
    -DCMAKE_CXX_FLAGS="-Wno-error=dangling-reference" \
    -G Ninja; then
    echo "CMake configuration failed - surrogate build system not properly configured"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Build the Catch2SurrogateTarget which compiles all surrogate translation units
# This validates that all headers are self-sufficient
if ! cmake --build build --target Catch2SurrogateTarget; then
    echo "Build of Catch2SurrogateTarget failed - surrogate build system not working"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

# Verify that surrogate files were actually generated
if [ ! -d "build/tests/surrogates" ] || [ -z "$(ls -A build/tests/surrogates/*.cpp 2>/dev/null)" ]; then
    echo "Surrogate files were not generated in build/tests/surrogates"
    echo 0 > /logs/verifier/reward.txt
    exit 1
fi

echo "Surrogate build system successfully configured and built"
test_status=0

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
